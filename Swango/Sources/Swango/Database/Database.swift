//
//  Database.swift
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
import SQLite

/// Database manager
public class Database {
    private let config: DatabaseConfig
    private var connection: Connection?
    
    init(config: DatabaseConfig) {
        self.config = config
        setupConnection()
    }
    
    private func setupConnection() {
        switch config.engine {
        case .sqlite:
            do {
                connection = try Connection(config.name)
                print("Connected to SQLite database at \(config.name)")
            } catch {
                print("Error connecting to SQLite database: \(error)")
            }
        case .postgresql, .mysql:
            print("PostgreSQL and MySQL support not yet implemented")
        }
    }
    
    /// Execute a raw SQL query
    public func execute(_ sql: String, parameters: [Any] = []) throws {
        guard let db = connection else {
            throw DatabaseError.noConnection
        }
        
        let statement = try db.prepare(sql)
        
        // Convert parameters to SQLite binding compatible types
        let bindableParams = parameters.map { convertToBindableParameter($0) }
        try statement.run(bindableParams)
    }
    
    /// Query the database and return results
    public func query(_ sql: String, parameters: [Any] = []) throws -> [[String: Any]] {
        guard let db = connection else {
            throw DatabaseError.noConnection
        }
        
        let statement = try db.prepare(sql)
        var results: [[String: Any]] = []
        
        // Convert parameters to SQLite binding compatible types
        let bindableParams = parameters.map { convertToBindableParameter($0) }
        
        for row in try statement.run(bindableParams) {
            var rowDict: [String: Any] = [:]
            for (index, name) in statement.columnNames.enumerated() {
                rowDict[name] = row[index]
            }
            results.append(rowDict)
        }
        
        return results
    }
    
    /// Convert a parameter to a SQLite-bindable type
    private func convertToBindableParameter(_ value: Any) -> Binding? {
        switch value {
        case let string as String:
            return string
        case let int as Int:
            return int
        case let int64 as Int64:
            return int64
        case let double as Double:
            return double
        case let bool as Bool:
            return bool
        case let date as Date:
            // Convert date to ISO 8601 string
            return ISO8601DateFormatter().string(from: date)
        case let data as Data:
            // SQLite.swift requires BLOB data to be wrapped in a custom type
            // Since this isn't supported directly, we'll encode data as a Base64 string
            return data.base64EncodedString()
        case is NSNull:
            return nil
        case let optionalValue as Any?:
            if let unwrapped = optionalValue {
                return convertToBindableParameter(unwrapped)
            } else {
                return nil
            }
        default:
            // If we can't convert it to a known SQLite type, convert to string
            return String(describing: value)
        }
    }
    
    /// Create a table from a model
    public func createTable(for model: Model.Type) throws {
        guard let db = connection else {
            throw DatabaseError.noConnection
        }
        
        let tableName = model.tableName
        let fields = model.fields
        
        var createStatement = "CREATE TABLE IF NOT EXISTS \(tableName) ("
        
        let fieldDefinitions = fields.map { field -> String in
            var definition = "\(field.name) \(field.sqlType)"
            
            if field.primaryKey {
                definition += " PRIMARY KEY"
                if field.autoIncrement {
                    definition += " AUTOINCREMENT"
                }
            }
            
            if field.unique {
                definition += " UNIQUE"
            }
            
            if !field.nullable {
                definition += " NOT NULL"
            }
            
            if let defaultValue = field.defaultValue {
                definition += " DEFAULT \(defaultValue)"
            }
            
            return definition
        }
        
        createStatement += fieldDefinitions.joined(separator: ", ")
        createStatement += ");"
        
        try execute(createStatement)
        print("Created table \(tableName)")
    }
}

/// Database errors
public enum DatabaseError: Error {
    case noConnection
    case queryError(String)
    case migrationError(String)
}
