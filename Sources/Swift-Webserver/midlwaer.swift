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

