# Swango

A Swift Web Framework Inspired by Django
Swango is a powerful, elegant web framework for Swift that brings the productivity and architecture of Django to the Swift ecosystem. Built for creating robust APIs and web applications, Swango combines the simplicity of Flask with the comprehensive feature set of Django.

✨ Features

Django-inspired Architecture: Organize your code in reusable apps with models, views, and routes
Powerful ORM: Define models in Swift with automatic table creation and migration
ViewSets & Serializers: Create RESTful APIs with minimal code
Middleware Support: Add cross-cutting concerns like authentication and logging
Template Engine: Simple template rendering for server-side view generation
Form Validation: Validate and process form submissions
Authentication: Built-in session and user authentication
Admin Dashboard: (Coming soon) Automatic admin interface for your models

🚀 Quick Start
Add Swango to your Package.swift:
swiftCopydependencies: [
    .package(url: "https://github.com/yourusername/Swango.git", from: "0.1.0")
]
Create your first Swango app:
swiftCopyimport Swango

// Configure your app
let settings = Settings(
    debug: true,
    database: DatabaseConfig.sqlite(filepath: "app.db")
)

// Create the application
let app = Swango(settings: settings)

// Define a simple route
app.get("/") { _ in
    return Response.text("Hello, Swango!")
}

// Start the server
try app.runServer(port: 8000)
📚 Define Models
swiftCopystruct Post: Model {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
    
    static var tableName: String { return "posts" }
    
    static var fields: [Field] {
        return [
            Field(name: "id", type: .text, primaryKey: true),
            Field(name: "title", type: .text, nullable: false),
            Field(name: "content", type: .text, nullable: false),
            Field(name: "created_at", type: .date)
        ]
    }
    
    // Required initializers and methods
    init(from row: [String: Any]) throws { /* ... */ }
    func toDictionary() -> [String: Any] { /* ... */ }
}
🔄 Create REST APIs
swiftCopy// Define a serializer
class PostSerializer: ModelSerializer<Post> {
    // Custom serialization logic
}

// Create a ViewSet
let postViewSet = ViewSet(serializer: PostSerializer(), database: db)

// Register with your app
postViewSet.register(with: app, basePath: "/api/posts")

// That's it! You now have a full REST API with:
// GET /api/posts - List all posts
// GET /api/posts/{id} - Get a specific post
// POST /api/posts - Create a post
// PUT /api/posts/{id} - Update a post
// DELETE /api/posts/{id} - Delete a post
🧩 Apps Architecture
Split your project into modular apps, similar to Django:
swiftCopyclass BlogApp: App {
    var name: String { return "blog" }
    var models: [Model.Type] { return [Post.self, Comment.self] }
    
    func registerURLs(with swango: Swango) {
        // Register routes specific to this app
    }
    
    func migrate(using db: Database) throws {
        // Run migrations for this app's models
    }
}

// Install the app
app.install(app: BlogApp())
🔒 Authentication
swiftCopy// Add session middleware
app.use(SessionMiddleware().middleware())

// Add authentication middleware
let authService = AuthService(database: db)
app.use(authService.authMiddleware(User.self))

// Protected route
app.get("/admin/dashboard") { request in
    guard let userId = request.session?.get("user_id") as String? else {
        return Response.redirect(to: "/login")
    }
    
    // User is authenticated
    return Response.text("Welcome to the admin dashboard!")
}
🛠️ Requirements

Swift 5.5+
macOS 10.15+

📘 Documentation
Visit our documentation for detailed guides and API reference.
🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

Fork the Project
Create your Feature Branch (git checkout -b feature/AmazingFeature)
Commit your Changes (git commit -m 'Add some AmazingFeature')
Push to the Branch (git push origin feature/AmazingFeature)
Open a Pull Request

📜 License
Distributed under the MIT License. See LICENSE for more information.
📣 Acknowledgements

Inspired by Django, the high-level Python Web framework
Built on Swift NIO for high-performance networking
Uses SQLite.swift for database operations


Built with ❤️ in Swift
