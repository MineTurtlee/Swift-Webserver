import Vapor

func routes(_ app: Application) throws {
    let origin = "mineturtle2.dpdns.org"
    app.get { req async in
        ReworkedHTML(title: "Mineturtlee's server", body: """
            <hero class="align-center">
                <h3 class="align-left">Mineturtlee</h3>
                <img src="/favicon.ico" class="align-right"></img>
            </hero>
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
            return Response(status: .imATeapot)
        default:
            return Response(status: .notFound)
        }
    }
    
    let status = app
        .grouped(SubdomainMiddleware(match: "status"))
        .grouped("status.\(origin)")
    status.get { req async in
        return Response(status: .ok)
    }
}
