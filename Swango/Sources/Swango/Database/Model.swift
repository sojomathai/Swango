//
//  Model.swift
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

/// Base protocol for database models
public protocol Model {
    /// Name of the database table
    static var tableName: String { get }
    
    /// Fields in the model
    static var fields: [Field] { get }
    
    /// Initialize from a database row
    init(from row: [String: Any]) throws
    
    /// Convert to a dictionary for database storage
    func toDictionary() -> [String: Any]
}

/// Field definition for models
public struct Field {
    public enum FieldType {
        case integer
        case text
        case real
        case blob
        case boolean
        case date
        
        var sqlType: String {
            switch self {
            case .integer, .boolean: return "INTEGER"
            case .text: return "TEXT"
            case .real: return "REAL"
            case .blob: return "BLOB"
            case .date: return "TEXT" // Store dates as ISO strings
            }
        }
    }
    
    public let name: String
    public let type: FieldType
    public let primaryKey: Bool
    public let autoIncrement: Bool
    public let nullable: Bool
    public let unique: Bool
    public let defaultValue: String?
    
    public init(
        name: String,
        type: FieldType,
        primaryKey: Bool = false,
        autoIncrement: Bool = false,
        nullable: Bool = true,
        unique: Bool = false,
        defaultValue: String? = nil
    ) {
        self.name = name
        self.type = type
        self.primaryKey = primaryKey
        self.autoIncrement = autoIncrement
        self.nullable = nullable
        self.unique = unique
        self.defaultValue = defaultValue
    }
    
    var sqlType: String {
        return type.sqlType
    }
}
