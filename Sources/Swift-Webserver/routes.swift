import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        HTML(value: """
<!DOCTYPE HTML>
<html>
<head>
<title>Mineturtlee's Website</title>
</head>
<body>
<p align=center>Hello world!</p>
</body>
</html>        
""")
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
}
