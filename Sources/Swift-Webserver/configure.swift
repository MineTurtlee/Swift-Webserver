import Vapor
import Foundation
import Logging

fileprivate let logger = Logger(label: "Swift-Webserver")

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    try await Downloader(URL(string:"https://github.com/Mineturtlee/Swift-Webserver/tree/main/Public")!, "Public")
    // app.middleware.use(SubdomainPathRewriteMiddleware())
    // reset
    app.middleware = .init()
    app.middleware.use(RouteLoggingMiddleware(logLevel: .debug))
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    let CorsConf = CORSMiddleware.Configuration(
        allowedOrigin: .originBased,
        allowedMethods: [.GET, .POST, .OPTIONS, .DELETE, .HEAD, .PATCH, .PUT, .brew],
        allowedHeaders: [HTTPHeaders.Name("*")])
    var CorsMiddleware = CORSMiddleware(configuration: CorsConf)
    app.middleware.use(CorsMiddleware, at: .beginning)
    app.middleware.use(ErrorHandlerMiddleware(), at: .end)
    // let middleware = StaticBundleMiddleware(bundle: .module)
    // app.middleware.use(middleware)

    // register routes
    try routes(app)
}
