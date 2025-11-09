//
//  midlwaer.swift
//  Swift-Webserver
//
//  Created by GreenyCells (Mineturtlee) on 11/10/25.
//

import Vapor
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ErrorHandlerMiddleware: AsyncMiddleware {
    func respond(to request: Vapor.Request, chainingTo next: any Vapor.AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch {
            return handleError(error, on: request)
        }
    }
    
    private func handleError(_ error: any Error, on request: Request) -> Response {
        let status: HTTPResponseStatus
        let reason: String
        var env: Environment
        do {
            env = try Environment.detect()
        } catch {
            env = Environment.init(name: "null")
        }

        switch error {
        case let abort as any AbortError:
            status = abort.status
            reason = abort.reason
        default:
            status = .internalServerError
            reason = error.localizedDescription
        }
        
        if env.name != "null" {
            if let webhook_url = Environment.get("webhook_url") {
                // https://discord.com/api/webhooks/1436718869330006148/BZh4MfXi3-70jB5Uaq6DsoonvjwN5ve0V7Iih_LE8QpLPhIwmDZWTGBERBrK7tQh30tV
                if webhook_url.starts(with: "https://discord.com") {
                    let url = webhook_url.replacingOccurrences(of: "https://", with: "")
                    if url.split(separator: "/").count == 5 {
                        let URL = URL(string: webhook_url)!
                        var request = URLRequest(url: URL)
                        request.httpMethod = "POST"
                        var body = WebhookBody(components: [])
                    }
                }
            }
        }

        let responseData = ErrorResponse(error: reason, status: status.code)
        var response = Response(status: status)
        try? response.content.encode(responseData)
        return response
    }
}

struct ErrorResponse: Content {
    let error: String
    let status: UInt
}
