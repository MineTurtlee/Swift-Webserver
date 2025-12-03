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
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <meta property="og:site_name" content="\(Environment.get("Name") ?? "")" />
                    <meta property="og:title" content="\(title)" />
                    <meta property="og:description" content="\(desc)" />
                    <meta property="og:type" content="\(contentType)" />
                    <link href="https://fonts.cdnfonts.com/css/sf-ui-display" rel="stylesheet">
                    <link rel="stylesheet prefetch" href="/styles.css">
                    <link rel="stylesheet prefetch" href="/misc.css">
                </head>
                <body>
                    <header class="heading">
                        <nav class="topbar">
                            <a href="/" class="brand">
                                <img src="/favicon.ico" alt="sun!!" />
                                <span>Mineturtlee</span>
                            </a>
            
                            <button class="menu-toggle" aria-label="Toggle menu"></button>
            
                            <ul class="nav-links">
                                <li><a href="/">Home</a></li>
                                <li><a href="/about">About</a></li>
                                <li><a href="/projects">Projects</a></li>
                                <li><a href="/contact">Contact</a></li>
                            </ul>
                        </nav>
                    </header>
                    <main class="content">
                        \(body)
                    </main>
                    <script>
                        document.addEventListener("DOMContentLoaded", () => {
                            const menuBtn = document.querySelector(".menu-toggle");
                            const navLinks = document.querySelector(".nav-links");

                            menuBtn.addEventListener("click", () => {
                                navLinks.classList.toggle("active");
                            });
                        });
                    </script>
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


struct SubdomainMiddleware: AsyncMiddleware {
    let match: String
    private let originDomain = "mineturtle2.dpdns.org"

    func respond(to req: Request, chainingTo next: any AsyncResponder) async -> Response {
        guard var host = req.headers.first(name: .host)?.lowercased() else {
            return Response(status: .badRequest)
        }

        if let colon = host.firstIndex(of: ":") {
            host = String(host[..<colon])
        }
        
        let subdomain = host
            .replacingOccurrences(of: ".\(originDomain)", with: "")
            .split(separator: ".")
            .first.map(String.init)
        
        guard let subdomain else {
            // If there's no subdomain (like just mineturtle2.dpdns.org), pass it as-is
            do {
                return try await next.respond(to: req)
            } catch {
                return Response(status: .internalServerError)
            }
        }
        
        let originalPath = req.url.path
        let newPath = "/\(subdomain).\(originDomain)/\(originalPath)"
        req.url.path = newPath
        
        do {
            let res = try await next.respond(to: req)
            return res
        } catch {
            return Response(status: .internalServerError)
        }
    }
}
