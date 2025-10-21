//
//  midlwaer.swift
//  Swift-Webserver
//
//  Created by GreenyCells (Mineturtlee) on 11/10/25.
//

import Vapor
import Logging

fileprivate let CustomLogger = Logger(label: "Swift-Webserver")

struct StaticBundleMiddleware: Middleware {
    let bundle: Bundle

    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        // Normalize path
        var path = request.url.path
        if path.hasPrefix("/") { path.removeFirst() }
        if path.isEmpty { path = "index.html" }

        // Locate the Public directory inside the bundle
        guard let publicDir = bundle.resourceURL?.appendingPathComponent("Public") else {
            CustomLogger.error("No Public directory in bundle")
            return next.respond(to: request)
        }

        // Build full file URL and normalize
        let fileURL = publicDir.appendingPathComponent(path).standardizedFileURL

        // Prevent directory traversal
        guard fileURL.path.hasPrefix(publicDir.path) else {
            CustomLogger.warning("Blocked directory traversal attempt: \(path)")
            return next.respond(to: request)
        }

        // Check existence
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            CustomLogger.warning("Resource not found in embedded bundle: \(path)")
            return next.respond(to: request)
        }

        // Stream the file (this already returns EventLoopFuture<Response>)
        let futureResponse = request.fileio.streamFile(at: fileURL.path)

        // Add headers once the response is ready
        return futureResponse.map { response in
            if let type = HTTPMediaType.fileExtension(fileURL.pathExtension) {
                response.headers.contentType = type
            } else {
                response.headers.contentType = .plainText
            }
            response.headers.add(name: .cacheControl, value: "public, max-age=3600")
            CustomLogger.info("Served embedded resource: \(fileURL.lastPathComponent)")
            return response
        }
    }
}
