//
//  REST.swift
//  Swango
/*  Created by sojo
 
## License

This project is available under a dual license:

- **GNU Affero General Public License v3.0 (AGPL-3.0)** for open source projects
- **Commercial License** for enterprise and commercial use

If you are using this software in a commercial or enterprise context, please contact us at info@techarm.ca to obtain a commercial license.
*/
import Foundation

/// Protocol for serializing and deserializing models
public protocol Serializer {
    associatedtype ModelType: Model
    
    /// Convert a model to a dictionary
    func serialize(_ model: ModelType) -> [String: Any]
    
    /// Convert a dictionary to a model
    func deserialize(_ data: [String: Any]) throws -> ModelType
    
    /// Validate input data
    func validate(_ data: [String: Any]) throws -> [String: Any]
}

/// Base implementation of Serializer
open class ModelSerializer<T: Model>: Serializer {
    public typealias ModelType = T
    
    public init() {}
    
    open func serialize(_ model: T) -> [String: Any] {
        return model.toDictionary()
    }
    
    open func deserialize(_ data: [String: Any]) throws -> T {
        return try T(from: data)
    }
    
    open func validate(_ data: [String: Any]) throws -> [String: Any] {
        // Base implementation just returns the data
        // Subclasses should implement validation logic
        return data
    }
}

/// Generic view set for REST API views
open class ViewSet<T: Model, S: Serializer> where S.ModelType == T {
    private let serializer: S
    private let database: Database
    
    public init(serializer: S, database: Database) {
        self.serializer = serializer
        self.database = database
    }
    
    /// Register routes with the application
    open func register(with app: Swango, basePath: String) {
        // List all instances
        app.get(basePath) { [unowned self] request in
            return try self.list(request: request)
        }
        
        // Get a single instance
        app.get("\(basePath)/<id>") { [unowned self] request in
            return try self.retrieve(request: request)
        }
        
        // Create a new instance
        app.post(basePath) { [unowned self] request in
            return try self.create(request: request)
        }
        
        // Update an instance
        app.put("\(basePath)/<id>") { [unowned self] request in
            return try self.update(request: request)
        }
        
        // Delete an instance
        app.delete("\(basePath)/<id>") { [unowned self] request in
            return try self.destroy(request: request)
        }
    }
    
    /// List all instances
    open func list(request: Request) throws -> Response {
        let sql = "SELECT * FROM \(T.tableName);"
        let results = try database.query(sql)
        
        let models = try results.map { row in
            try serializer.deserialize(row)
        }
        
        let serialized = models.map { serializer.serialize($0) }
        return try Response.jsonObject(serialized)
    }
    
    /// Retrieve a single instance
    open func retrieve(request: Request) throws -> Response {
        guard let id = request.param("id") else {
            throw SwangoError.invalidRequest("Missing ID parameter")
        }
        
        let sql = "SELECT * FROM \(T.tableName) WHERE id = ? LIMIT 1;"
        let results = try database.query(sql, parameters: [id])
        
        guard let row = results.first else {
            return Response.text("Object not found", status: .notFound)
        }
        
        let model = try serializer.deserialize(row)
        let serialized = serializer.serialize(model)
        return try Response.jsonObject(serialized)
    }
    
    /// Create a new instance
    open func create(request: Request) throws -> Response {
        guard let body = request.body else {
            throw SwangoError.invalidRequest("Missing request body")
        }
        
        guard let jsonData = try? JSONSerialization.jsonObject(with: body, options: []),
              let jsonDict = jsonData as? [String: Any] else {
            throw SwangoError.invalidRequest("Invalid JSON")
        }
        
        let validatedData = try serializer.validate(jsonDict)
        let model = try serializer.deserialize(validatedData)
        
        let modelDict = model.toDictionary()
        let columns = modelDict.keys.joined(separator: ", ")
        let placeholders = Array(repeating: "?", count: modelDict.count).joined(separator: ", ")
        let values = modelDict.values.map { $0 }
        
        let sql = "INSERT INTO \(T.tableName) (\(columns)) VALUES (\(placeholders));"
        try database.execute(sql, parameters: values)
        
        let serialized = serializer.serialize(model)
        return try Response.jsonObject(serialized, status: .created)
    }
    
    /// Update an instance
    open func update(request: Request) throws -> Response {
        guard let id = request.param("id") else {
            throw SwangoError.invalidRequest("Missing ID parameter")
        }
        
        guard let body = request.body else {
            throw SwangoError.invalidRequest("Missing request body")
        }
        
        guard let jsonData = try? JSONSerialization.jsonObject(with: body, options: []),
              let jsonDict = jsonData as? [String: Any] else {
            throw SwangoError.invalidRequest("Invalid JSON")
        }
        
        let validatedData = try serializer.validate(jsonDict)
        
        // Check if the object exists
        let checkSql = "SELECT * FROM \(T.tableName) WHERE id = ? LIMIT 1;"
        let results = try database.query(checkSql, parameters: [id])
        
        guard results.first != nil else {
            return Response.text("Object not found", status: .notFound)
        }
        
        // Update the object
        let setClause = validatedData.keys.map { "\($0) = ?" }.joined(separator: ", ")
        var updateValues = validatedData.values.map { $0 }
        updateValues.append(id)
        
        let updateSql = "UPDATE \(T.tableName) SET \(setClause) WHERE id = ?;"
        try database.execute(updateSql, parameters: updateValues)
        
        // Fetch the updated object
        let fetchSql = "SELECT * FROM \(T.tableName) WHERE id = ? LIMIT 1;"
        let updatedResults = try database.query(fetchSql, parameters: [id])
        
        guard let updatedRow = updatedResults.first else {
            throw SwangoError.internalError(NSError(domain: "Swango", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch updated object"]))
        }
        
        let updatedModel = try serializer.deserialize(updatedRow)
        let serialized = serializer.serialize(updatedModel)
        return try Response.jsonObject(serialized)
    }
    
    /// Delete an instance
    open func destroy(request: Request) throws -> Response {
        guard let id = request.param("id") else {
            throw SwangoError.invalidRequest("Missing ID parameter")
        }
        
        // Check if the object exists
        let checkSql = "SELECT * FROM \(T.tableName) WHERE id = ? LIMIT 1;"
        let results = try database.query(checkSql, parameters: [id])
        
        guard results.first != nil else {
            return Response.text("Object not found", status: .notFound)
        }
        
        // Delete the object
        let deleteSql = "DELETE FROM \(T.tableName) WHERE id = ?;"
        try database.execute(deleteSql, parameters: [id])
        
        return Response(status: .noContent)
    }
}
