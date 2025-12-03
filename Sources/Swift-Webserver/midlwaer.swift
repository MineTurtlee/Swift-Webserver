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
import Logging

fileprivate let logger = Logger(label: "Swift-Webserver")

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
            logger.error("env not found (error)")
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
                    let URL = URL(string: webhook_url)!
                    var request = URLRequest(url: URL)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let text = TextDisplay(content: "## An error occurred! (web)")
                    let separator = Separator()
                    let text2 = TextDisplay(content: error.localizedDescription)

                    // Container children must be AnyEncodable
                    let container = Container(accent_color: 0xff0000, components: [
                        AnyEncodable(text),
                        AnyEncodable(separator),
                        AnyEncodable(text2)
                    ])
                    

                    // ActionRow children are concrete buttons
                    let length = 16
                    let chars = "abcdefghijklmnopqrstuvwxyz0123456789"
                    
                    let randomID = String((0..<16).map { _ in chars.randomElement()! })
                    
                    let button = Button(style: .secondary, label: "Credits to Mineturtle2", custom_id: randomID, disabled: true)
                    let actrow = ActionRow(components: [button])

                    // Top-level components are protocol-conforming objects
                    let body = WebhookBody(components: [
                        container,
                        actrow
                    ])

                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted]
                    var jsonData: Data
                    do {
                        jsonData = try encoder.encode(body)
                        logger.debug("Body: \(String(describing: String(data:jsonData, encoding: .utf8)))")
                        request.httpBody = jsonData
                        let (data, response) = try await URLSession.shared.data(for: request)
                        /* let resp = response as! HTTPURLResponse
                        logger.info("Status Code: \(resp.statusCode)")
                        let stringified = String(data: data, encoding: .utf8)
                        logger.info("Data: \(String(describing: stringified))")
                         */
                    } catch {
                        logger.debug("\(error.localizedDescription)")
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
