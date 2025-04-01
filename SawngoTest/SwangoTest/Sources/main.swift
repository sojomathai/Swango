import Foundation
import Swango

print("Testing Swango Framework")

// Create database configuration
let dbConfig = DatabaseConfig.sqlite(filepath: ":memory:") // In-memory database for testing

// Create application settings
let settings = Settings(
    debug: true,
    database: dbConfig
)

// Create the application
let app = Swango(settings: settings)

// Define a simple model
struct User: Model, Authenticatable {
    let id: String
    let username: String
    let password: String
    
    static var tableName: String { return "users" }
    
    static var fields: [Field] {
        return [
            Field(name: "id", type: .text, primaryKey: true),
            Field(name: "username", type: .text, nullable: false, unique: true),
            Field(name: "password", type: .text, nullable: false)
        ]
    }
    
    init(id: String = UUID().uuidString, username: String, password: String) {
        self.id = id
        self.username = username
        self.password = password
    }
    
    init(from row: [String: Any]) throws {
        guard let id = row["id"] as? String,
              let username = row["username"] as? String,
              let password = row["password"] as? String else {
            throw SwangoError.invalidRequest("Invalid user data")
        }
        
        self.id = id
        self.username = username
        self.password = password
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "username": username,
            "password": password
        ]
    }
    
    func checkPassword(_ password: String) -> Bool {
        return self.password == User.hashPassword(password)
    }
    
    static func hashPassword(_ password: String) -> String {
        // Simple hash for testing
        return password
    }
}

// Create a test app
class TestApp: App {
    var name: String { return "test" }
    var models: [Model.Type] { return [User.self] }
    
    private weak var swango: Swango?
    private var database: Database?
    
    func connect(to swango: Swango) {
        self.swango = swango
        self.database = swango.getDatabase()
    }
    
    func registerURLs(with swango: Swango) {
        swango.get("/") { _ in
            return Response.text("Hello from Swango!")
        }
        
        swango.get("/users") { [weak self] _ in
            guard let self = self, let db = self.database else {
                throw SwangoError.internalError(NSError())
            }
            
            let results = try db.query("SELECT * FROM users")
            return try Response.jsonObject(results)
        }
    }
    
    func migrate(using db: Database) throws {
        try db.createTable(for: User.self)
        
        // Add a test user
        let user = User(username: "test", password: "password")
        let dict = user.toDictionary()
        try db.execute(
            "INSERT INTO users (id, username, password) VALUES (?, ?, ?)",
            parameters: [dict["id"]!, dict["username"]!, dict["password"]!]
        )
        
        print("Created test user: \(user.username)")
    }
}

// Install the app
let testApp = TestApp()
app.install(app: testApp)

// Add session middleware
let sessionMiddleware = SessionMiddleware()
app.use(sessionMiddleware.middleware())

// Start the server
do {
    print("Starting server on port 8000...")
    try app.runServer(port: 8000)
} catch {
    print("Error starting server: \(error)")
}
