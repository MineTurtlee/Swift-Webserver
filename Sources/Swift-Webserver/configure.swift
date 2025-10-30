import Vapor
import Foundation
import Logging

fileprivate let logger = Logger(label: "Swift-Webserver")

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    try await Downloader(URL(string:"https://github.com/Mineturtlee/Swift-Webserver/tree/main/Public")!, "Public")
    // app.middleware.use(SubdomainPathRewriteMiddleware())
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // let middleware = StaticBundleMiddleware(bundle: .module)
    // app.middleware.use(middleware)

    // register routes
    try routes(app)
}
