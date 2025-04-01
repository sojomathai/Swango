//
//  DatabaseConfig.swift
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

/// Database configuration
public struct DatabaseConfig {
    public enum Engine {
        case sqlite
        case postgresql
        case mysql
    }
    
    public let engine: Engine
    public let name: String
    public let host: String?
    public let port: Int?
    public let username: String?
    public let password: String?
    
    public init(
        engine: Engine = .sqlite,
        name: String,
        host: String? = nil,
        port: Int? = nil,
        username: String? = nil,
        password: String? = nil
    ) {
        self.engine = engine
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.password = password
    }
    
    public static func sqlite(filepath: String) -> DatabaseConfig {
        return DatabaseConfig(engine: .sqlite, name: filepath)
    }
}
