//
//  File.swift
//  Swango
//
/*  Created by sojo
 
## License

This project is available under a dual license:

- **GNU Affero General Public License v3.0 (AGPL-3.0)** for open source projects
- **Commercial License** for enterprise and commercial use

If you are using this software in a commercial or enterprise context, please contact us at info@techarm.ca to obtain a commercial license.
*/

import Foundation
import NIO
import NIOHTTP1

/// The main application class that serves as the entry point for the Swango framework
public class Swango {
    // MARK: - Properties
    
    private var router = Router()
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private var middlewares: [Middleware] = []
    private var settings: Settings
    private var installedApps: [App] = []
    private var database: Database?
    
    // MARK: - Initialization
    
    public init(settings: Settings = Settings()) {
        self.settings = settings
        
        // Connect to database if configured
        if let dbConfig = settings.database {
            self.database = Database(config: dbConfig)
        }
    }
    
    // MARK: - Configuration
    
    /// Install an app to the Swango project
    @discardableResult
    public func install(app: App) -> Swango {
        app.connect(to: self)
        installedApps.append(app)
        return self
    }
    
    /// Add a middleware to the application
    @discardableResult
    public func use(_ middleware: @escaping Middleware) -> Swango {
        middlewares.append(middleware)
        return self
    }
    
    /// Get the database connection
    public func getDatabase() -> Database? {
        return database
    }
    
    // MARK: - Server
    
    /// Start the server on the specified port
    public func runServer(host: String = "0.0.0.0", port: Int = 8000) throws {
        // Run migrations first
        try runMigrations()
        
        print("Starting Swango server on port \(port)...")
        
        let bootstrap = ServerBootstrap(group: eventLoopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPHandler(router: self.router, middlewares: self.middlewares))
                }
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        
        let serverChannel = try bootstrap.bind(host: host, port: port).wait()
        print("🚀 Server started and listening on \(serverChannel.localAddress!)")
        
        // Register routes from all installed apps
        for app in installedApps {
            app.registerURLs(with: self)
        }
        
        try serverChannel.closeFuture.wait()
    }
    
    /// Run migrations for all installed apps
    private func runMigrations() throws {
        guard let db = database else {
            print("Warning: No database configured, skipping migrations")
            return
        }
        
        print("Running migrations...")
        for app in installedApps {
            try app.migrate(using: db)
        }
        print("Migrations completed successfully")
    }
    
    /// Gracefully shutdown the server
    public func shutdown() throws {
        print("Shutting down Swango server...")
        try eventLoopGroup.syncShutdownGracefully()
    }
    
    // MARK: - URL Registration
    
    /// Register a GET route
    public func get(_ path: String, handler: @escaping RouteHandler) {
        router.addRoute(method: .GET, path: path, handler: handler)
    }
    
    /// Register a POST route
    public func post(_ path: String, handler: @escaping RouteHandler) {
        router.addRoute(method: .POST, path: path, handler: handler)
    }
    
    /// Register a PUT route
    public func put(_ path: String, handler: @escaping RouteHandler) {
        router.addRoute(method: .PUT, path: path, handler: handler)
    }
    
    /// Register a DELETE route
    public func delete(_ path: String, handler: @escaping RouteHandler) {
        router.addRoute(method: .DELETE, path: path, handler: handler)
    }
    
    /// Register a PATCH route
    public func patch(_ path: String, handler: @escaping RouteHandler) {
        router.addRoute(method: .PATCH, path: path, handler: handler)
    }
}
