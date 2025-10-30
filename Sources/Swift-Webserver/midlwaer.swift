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
        var path = request.url.path
        if path.hasPrefix("/") { path.removeFirst() }
        if path.isEmpty { path = "abort" }

        if path == "abort" {
            CustomLogger.warning("Empty path, leaving")
            return next.respond(to: request)
        }
        // if let fileURL = bundle.resourceURL?
            // .appendingPathComponent("Public")
            // .appendingPathComponent(path)
            // .standardizedFileURL,
           // FileManager.default.fileExists(atPath: fileURL.path) {
        guard let fileURL = bundle.url(forResource: path, withExtension: nil),
              let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
              values.isRegularFile == true else {
            CustomLogger.warning("Resource not found or unreadable: \(path)")
            return next.respond(to: request)
        }
        do {
            let data = try Data(contentsOf: fileURL)
            var response = Response(status: .ok, body: .init(data: data))

            if let type = HTTPMediaType.fileExtension(fileURL.pathExtension) {
                response.headers.contentType = type
            }

            response.headers.add(name: .cacheControl, value: "public, max-age=3600")
            CustomLogger.info("Served embedded resource: \(fileURL.lastPathComponent)")
            return request.eventLoop.makeSucceededFuture(response)
        } catch {
            CustomLogger.error("Error loading resource: \(error)")
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}

/* struct SubdomainFileMiddleware: Middleware {
 let subdomain: String
 let fileMiddleware: FileMiddleware
 
 func respond(to req: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
 if !subdomain.isEmpty {
 guard let host = req.headers.first(name: .host)?.lowercased(),
 host.hasPrefix(subdomain + ".") else {
 return req.eventLoop.makeFailedFuture(Abort(.notFound))
 }
 }
 
 return fileMiddleware.respond(to: req, chainingTo: next)
 }
 }
 */

/* struct SubdomainPathRewriteMiddleware: Middleware {
    private let originDomain = "mineturtle2.dpdns.org"

    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        guard let host = request.headers.first(name: .host)?.lowercased(),
              host.hasSuffix(originDomain) else {
            return request.eventLoop.makeFailedFuture(Abort(.badRequest))
        }

        // Extract subdomain from the host
        let subdomain = host
            .replacingOccurrences(of: ".\(originDomain)", with: "")
            .split(separator: ".")
            .first.map(String.init)

        guard let subdomain else {
            // If there's no subdomain (like just mineturtle2.dpdns.org), pass it as-is
            return next.respond(to: request)
        }

        // Rewrite the path internally
        let originalPath = request.url.path
        let newPath = "/\(subdomain)\(originalPath)"

        // Overwrite the URL path
        request.url.path = newPath

        // Continue chain
        return next.respond(to: request)
    }
}
*/
