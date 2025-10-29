//
//  CustomImplementation.swift
//  Swift-Webserver
//
//  Created by GreenyCells (Mineturtlee) on 10/10/25.
//
import Vapor

struct HTML {
    let value: String
}

struct ReworkedHTML {
    let title: String
    let body: String
    let desc: String
    let contentType: String
}

struct JSON<T: Encodable> {
    let value: T
}

extension HTML: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html")
        return .init(status: .ok, headers: headers, body: .init(string: value))
    }
}

extension ReworkedHTML: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html")
        var Prettified = """
            <!DOCTYPE HTML>
            <html prefix="og: https://ogp.me/ns#">
                <head>
                    <title>\(title)</title>
                    <meta property="og:site_name" content="\(Environment.get("Name") ?? "")" />
                    <meta property="og:title" content="\(title)" />
                    <meta property="og:description" content="\(desc)" />
                    <meta property="og:type" content="\(contentType)" />
                    <link rel="stylesheet prefetch" href="/fonts.css">
                    <link rel="stylesheet prefetch" href="/styles.css">
                    <link rel="stylesheet prefetch" href="/misc.css">
                </head>
                <body>
                    \(body)
                </body>
            </html>
            """
        return .init(status: .ok, headers: headers, body: .init(string: Prettified))
    }
}

extension JSON: AsyncResponseEncodable {
    public func encodeResponse(for request: Request) async throws -> Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/json")
        let data = try JSONEncoder().encode(value)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Failed to convert JSON data to string")
        }
        return .init(status: .ok, headers: headers, body: .init(string: jsonString))
    }
}

extension HTTPMethod {
    static let brew = HTTPMethod(rawValue: "BREW")
}


struct SubdomainMiddleware: Middleware {
    let match: String

    func respond(to req: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        guard var host = req.headers.first(name: .host)?.lowercased() else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Missing host header"))
        }
        
        if let colon = host.firstIndex(of: ":") {
            host = String(host[..<colon])
        }
        
        if match.isEmpty {
            if host == "localhost" || host == "[::1]" || host == "127.0.0.1" {
                return next.respond(to: req)
            }
            let parts = host.split(separator: ".")
            if parts.count > 2 {
                return req.eventLoop.makeFailedFuture(Abort(.badGateway, reason: "Server error"))
            }
        } else {
            guard host.hasPrefix(match + ".") else {
                return req.eventLoop.makeFailedFuture(Abort(.notFound))
            }
        }
        
        return next.respond(to: req)
    }
}

