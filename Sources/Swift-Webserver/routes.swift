import Vapor

func routes(_ app: Application) throws {
    let origin = "mineturtle2.dpdns.org"
    app.get { req async in
        ReworkedHTML(title: "Mineturtlee's server", body: """
            <hero class="root-hero">
                <div class="root-hero-text">
                    <h3 align="left">Mineturtlee</h3>
                    <p align="left">A hobbyist developer.</p>
                </div>
                <img src="/favicon.ico" class="align-right" />
            </hero>
            """, desc: "Just a silly website made by Mineturtle2", contentType: "website")
    }
    
    app.get("contact") { req async in
        ReworkedHTML(title: "Contact | Mineturtlee's server", body:"""
                        <h1 align="center">hi</h1>
                        """, desc: "Mineturtlee's contact methods", contentType: "website")
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
