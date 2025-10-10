import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    //let fileMiddleware = FileMiddleware(
        //publicDirectory: app.directory.publicDirectory
    //)
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
