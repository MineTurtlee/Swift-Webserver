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
            <div>
                <h1 align="center">Technologies & Skills</h1><div class="cards">
                <!-- skills cards -->
                <div class="card">
                    <a href="https://python.org">
                        <p class="python">python</p>
                        <h2 align="center">Python</h2>
                    </a>
                </div>
                <div class="card">
                    <a href="https://swift.org">
                        <p class="swift">swift</p>
                        <h2 align="center">Swift</h2>
                    </a>
                </div>
                <div class="card">
                    <a href="https://mongodb.com">
                        <p class="mongodb">mongo</p>
                        <h2 align="center">MongoDB</h2>
                    </a>
                </div>
                <div class="card">
                    <a href="https://javascript.com">
                        <p class="js">js</p>
                        <h2 align="center">JavaScript</h2>
                    </a>
                </div>
            </div>
            <script>
                document.addEventListener("DOMContentLoaded", () => {
                    const menuBtn = document.querySelector(".menu-toggle");
                    const navLinks = document.querySelector(".nav-links");

                    menuBtn.addEventListener("click", () => {
                        navLinks.classList.toggle("active");
                    });
                });
            </script>
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
