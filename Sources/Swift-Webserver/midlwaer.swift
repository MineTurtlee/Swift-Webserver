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

        // Try to find the file in the bundle's Public folder
        if let fileURL = bundle.resourceURL?
            .appendingPathComponent("Public")
            .appendingPathComponent(path)
            .standardizedFileURL,
           FileManager.default.fileExists(atPath: fileURL.path) {

            do {
                let data = try Data(contentsOf: fileURL)
                var response = Response(status: .ok, body: .init(data: data))

                // Content type
                if let type = HTTPMediaType.fileExtension(fileURL.pathExtension) {
                    response.headers.contentType = type
                }

                // Cache control
                response.headers.add(name: .cacheControl, value: "public, max-age=3600")

                CustomLogger.info("Served embedded resource: \(fileURL.lastPathComponent)")
                return request.eventLoop.makeSucceededFuture(response)
            } catch {
                CustomLogger.error("Error loading resource: \(error)")
                return request.eventLoop.makeFailedFuture(error)
            }
        } else {
            // Not found, pass to next responder
            CustomLogger.warning("Resource not found in embedded bundle: \(path)")
            return next.respond(to: request)
        }
    }
}
