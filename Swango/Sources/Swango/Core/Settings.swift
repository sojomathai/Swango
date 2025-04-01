//
//  Settings.swift
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
/// Configuration settings for a Swango application
public class Settings {
    public var debug: Bool
    public var allowedHosts: [String]
    public var database: DatabaseConfig?
    public var middlewares: [String]
    
    public init(
        debug: Bool = true,
        allowedHosts: [String] = ["*"],
        database: DatabaseConfig? = nil,
        middlewares: [String] = ["session", "csrf", "auth"]
    ) {
        self.debug = debug
        self.allowedHosts = allowedHosts
        self.database = database
        self.middlewares = middlewares
    }
}
