import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging

fileprivate let logger = Logger(label: "Swift-Webserver.Downloader")

enum DownloaderErrors: Error {
    case InvalidURL(String)
    case APIError(String)
    case AppError(String)
    case ConstructionError(String)
    case Unknown(String)
}

struct RepoIn4 {
    let owner: String
    let repository: String
    let branch: String
    let path: String
    let APIPrefix: String
}

struct GHContent: Decodable {
    let type: String
    let path: String
    let downloadURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case type
        case path
        case downloadURL = "download_url"
    }
}

actor DownloadStats {
    private(set) var fileCount = 0

    func incrementFileCount() {
        fileCount += 1
    }

    func getFileCount() -> Int {
        return fileCount
    }
}

class DownloaderStats: @unchecked Sendable {
    var repoinfo: RepoIn4!
    var FM = FileManager.default
    var targetURL: URL!
    var stats = DownloadStats()
    
    static let shared = DownloaderStats()
    
    private init() {}
}

class Downloader {
    // @MainActor private var folderCount = 0
    // private var finalURL: URL
    let stats = DownloaderStats.shared
    init(_ ghURL: URL, _ targerDir: String) async throws {
        stats.repoinfo = try Downloader.parse(ghURL)
        let currentDir = URL(fileURLWithPath: stats.FM.currentDirectoryPath)
        stats.targetURL = currentDir.appendingPathComponent(targerDir)
        // self.finalURL = URL(string: "\(self.repoinfo.APIPrefix)/\(self.repoinfo.path)?ref=\(self.repoinfo.branch)")!
        if stats.FM.fileExists(atPath: stats.targetURL.path) {
            do {
                try stats.FM.removeItem(atPath: stats.targetURL.path)
            } catch {
                throw DownloaderErrors.Unknown("Folder removal error - do you have permissions to do so?")
            }
        }
        
        do {
            try stats.FM.createDirectory(at: stats.targetURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw DownloaderErrors.Unknown("Folder creation error..")
        }
        do {
            try await downloadDirectory()
        } catch {
            logger.error("Download failed")
        }
    }
    
    public func downloadDirectory() async throws {
        logger.info("Starting download for repository: \(stats.repoinfo.repository) / \(stats.repoinfo.branch) / \(stats.repoinfo.path)")
        try await mapContent(directoryPath: stats.repoinfo.path, stats: stats)
        let downloadedFiles = await stats.stats.getFileCount()
        logger.info("download complete: \(downloadedFiles) files downloaded.")
    }
    
    static fileprivate func parse(_ url: URL) throws -> RepoIn4 {
        let path = url.path
        let splitted = path.split(separator: "/")
        guard splitted.count >= 4 else {
            throw DownloaderErrors.InvalidURL("Too few components, not a valid GH URL")
        }
        
        guard splitted[2] == "tree" else {
            throw DownloaderErrors.InvalidURL("Probably a repo URL, throwing anyways")
        }
        let startIndex = path.index(path.startIndex, offsetBy: 1)
        let owner = splitted[0]
        let repo = splitted[1]
        let branch = splitted[3]
        let path2branch = "tree/\(branch)"
        guard let branchEnd = path.range(of: path2branch, options: [], range: startIndex..<path.endIndex) else {
            throw DownloaderErrors.InvalidURL("No branch found, throwing")
        }
        
        let pathStart = branchEnd.upperBound
        
        let baseURL = "https://api.github.com/repos/\(owner)/\(repo)/contents"
        
        let resPath = String(path[pathStart...]).dropFirst()
        
        return RepoIn4(
            owner: String(owner),
            repository: String(repo),
            branch: String(branch),
            path: String(resPath),
            APIPrefix: baseURL
        )
    }
}

func mapContent(directoryPath: String, stats: DownloaderStats) async throws {
    // var request = URLRequest(url: self.finalURL)
    guard var components = URLComponents(string: "\(stats.repoinfo.APIPrefix)/\(directoryPath)") else {
        throw DownloaderErrors.ConstructionError("Failed to build API URL for path: \(directoryPath)")
    }
    components.queryItems = [URLQueryItem(name: "ref", value: stats.repoinfo.branch)]
    guard let url = components.url else {
        throw DownloaderErrors.ConstructionError("Invalid URL components.")
    }
    
    var request = URLRequest(url: url)
    request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw DownloaderErrors.AppError("Invalid response")
    }
    
    let statusCode = httpResponse.statusCode
    
    if statusCode != 200 {
        throw DownloaderErrors.APIError("The status code is NOT 200. Throwing.")
    }
    
    let contents = try JSONDecoder().decode([GHContent].self, from: data)
    
    try await withThrowingTaskGroup(of: Void.self) { group in
        for item in contents {
            switch item.type {
            case "dir":
                let nextPath = item.path
                group.addTask {
                    try await mapContent(directoryPath: nextPath, stats: stats)
                }

            case "file":
                let fileContent = item
                let repoinfo = stats.repoinfo
                let targetURL = stats.targetURL
                let FM = stats.FM
                let downloadStats = stats.stats
                let stats = stats

                group.addTask {
                    let localFilePath = try calculateLocalPath(for: fileContent, stats: stats)
                    try await downloadFile(content: fileContent, localPath: localFilePath)
                    await downloadStats.incrementFileCount()
                }
            default:
                continue
            }
        }
        try await group.waitForAll()
    }
}

func calculateLocalPath(for content: GHContent, stats: DownloaderStats) throws -> URL {
    let fullPath = content.path
    let resourceRoot = stats.repoinfo.path
    
    guard let range = fullPath.range(of: resourceRoot) else {
        throw DownloaderErrors.AppError("Path mismatch.")
    }
    
    let relativePath = fullPath[range.upperBound...].dropFirst()
    
    return stats.targetURL.appendingPathComponent(String(relativePath))
}

func downloadFile(content: GHContent, localPath: URL) async throws {
    guard let url = content.downloadURL else {
        throw DownloaderErrors.AppError("Error in extracting the URL to download files")
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpreq = response as? HTTPURLResponse else {
        throw DownloaderErrors.APIError("Invalid response when downloading")
    }
    
    let statusCde = httpreq.statusCode
    if statusCde != 200 {
        throw DownloaderErrors.APIError("Not 200 Code when downloading, throwing")
    }
    
    let directory = localPath.deletingLastPathComponent()
    try FileManager().createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    do {
        try data.write(to: localPath, options: .atomic)
    } catch {
        throw DownloaderErrors.AppError("Failed to save file")
    }
    logger.info("Successfully downloaded: \(localPath.lastPathComponent)")
}
