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
            return await handleError(error, on: request)
        }
    }
    
    private func handleError(_ error: any Error, on request: Request) async -> Response {
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
                if webhook_url.starts(with: "https://discord.com") {
                    let url = webhook_url.replacingOccurrences(of: "https://", with: "")
                    if url.split(separator: "/").count == 5 {
                        let URL = URL(string: webhook_url)!
                        var request = URLRequest(url: URL)
                        request.httpMethod = "POST"
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        let button = Button(style: ButtonStyle.secondary, label: "Credits to Mineturtle2", disabled: true)
                        let text = TextDisplay(content: "## An error occurred! (web)")
                        let separator = Separator()
                        let text2 = TextDisplay(content: error.localizedDescription)
                        let container = Container(components: [text, text2], accent_color: 0xff0000)
                        let actrow = ActionRow(components: [button])
                        var body = WebhookBody(content: nil, components: [container, actrow])
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                        var jsonData: Data
                        do {
                            jsonData = try encoder.encode(body)
                            request.httpBody = jsonData
                            let (data, response) = try await URLSession.shared.data(for: request)
                        } catch {
                            // does nothing instead, we alr know
                        }
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
