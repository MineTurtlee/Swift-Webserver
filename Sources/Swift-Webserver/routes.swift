import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        ReworkedHTML(title: "Mineturtlee's server", body: """
            <header class="topbar">
              <div class="logo">
                <a href="/">Mineturtlee</a>
              </div>
              <nav class="nav">
                <a href="/">Home</a>
              </nav>
            </header>
            <h3 class="indented">Mineturtlee's website</h3>
            """, desc: "Just a silly website made by Mineturtle2 | Root", contentType: "website")
    }
    
    app.on(.brew, "brew", ":type") { req async -> Response in
        guard let type = req.parameters.get("type") else {
            return Response(status: .badRequest)
        }
        switch type {
        case "tea":
            return Response(status: .ok)
        case "coffee":
            return Response(status: HTTPResponseStatus(statusCode: 418, reasonPhrase: "I'm a teapot"))
        default:
            return Response(status: .notFound)
        }
    }
}
