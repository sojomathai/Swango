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

/// Protocol for Swango apps
public protocol App {
    /// Name of the app
    var name: String { get }
    
    /// Models defined in this app
    var models: [Model.Type] { get }
    
    /// Connect the app to the Swango instance
    func connect(to swango: Swango)
    
    /// Register URLs for this app
    func registerURLs(with swango: Swango)
    
    /// Run migrations for this app
    func migrate(using db: Database) throws
}
