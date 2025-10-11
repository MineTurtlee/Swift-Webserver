import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        ReworkedHTML(title: "Mineturtlee's server", body: """
            <p align=center>hello</p>
            """, desc: "Just a silly website made by Mineturtle2", contentType: "website")
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
}
