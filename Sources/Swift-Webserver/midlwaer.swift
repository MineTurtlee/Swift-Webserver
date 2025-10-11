//
//  midlwaer.swift
//  Swift-Webserver
//
//  Created by GreenyCells (Mineturtlee) on 11/10/25.
//

import Vapor
import Logging

fileprivate let CustomLogger = Logger(label: "Swift-Webserver")

struct midlwaer: Middleware {
    let bundle: Bundle

    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        // Normalize path
        var path = request.url.path
        if path.hasPrefix("/") { path.removeFirst() }

        // split
        let url = URL(fileURLWithPath: path)
        let fileName = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension.isEmpty ? nil : url.pathExtension

        // finding the file
        if let fileURL = bundle.url(forResource: fileName,
                                    withExtension: fileExtension,
                                    subdirectory: "Public") {
            do {
                let data = try Data(contentsOf: fileURL)
                var response = Response(status: .ok, body: .init(data: data))

                // cotnetn type
                if let ext = fileExtension,
                   let type = HTTPMediaType.fileExtension(ext) {
                    response.headers.contentType = type
                }

                // some cache header control thingy
                response.headers.add(name: .cacheControl, value: "public, max-age=3600")

                CustomLogger.info("Served embedded resource: \(fileURL.lastPathComponent)")
                return request.eventLoop.makeSucceededFuture(response)
            } catch {
                CustomLogger.error("Error loading resource: \(error)")
                return request.eventLoop.makeFailedFuture(error)
            }
        }
        else {
            // not found case
            CustomLogger.warning("Resource not found in embedded bundle: \(path)")
            return next.respond(to: request)
        }
    }
}
