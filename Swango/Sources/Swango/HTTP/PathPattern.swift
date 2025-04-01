//
//  PathPattern.swift
//  Swango
/*  Created by sojo
 
## License

This project is available under a dual license:

- **GNU Affero General Public License v3.0 (AGPL-3.0)** for open source projects
- **Commercial License** for enterprise and commercial use

If you are using this software in a commercial or enterprise context, please contact us at info@techarm.ca to obtain a commercial license.
*/

import Foundation

/// Class for handling URL path patterns and extracting parameters
class PathPattern {
    private enum Component {
        case literal(String)
        case parameter(String)
        case wildcard
    }
    
    private let components: [Component]
    
    init(pattern: String) {
        self.components = PathPattern.parse(pattern: pattern)
    }
    
    /// Parse a path pattern into components
    private static func parse(pattern: String) -> [Component] {
        let parts = pattern.split(separator: "/")
        return parts.map { part in
            if part == "*" {
                return .wildcard
            } else if part.hasPrefix("<") && part.hasSuffix(">") {
                let paramName = String(part.dropFirst().dropLast())
                return .parameter(paramName)
            } else {
                return .literal(String(part))
            }
        }
    }
    
    /// Match a path against this pattern and extract parameters
    func match(path: String) -> [String: String]? {
        let parts = path.split(separator: "/").map { String($0) }
        
        // Quick check for component count match (except for wildcards)
        if !components.contains(where: { if case .wildcard = $0 { return true } else { return false } })
           && parts.count != components.count {
            return nil
        }
        
        var params: [String: String] = [:]
        
        for (index, component) in components.enumerated() {
            // Handle wildcard at the end
            if case .wildcard = component {
                return params
            }
            
            // Ensure we haven't gone past the end of the path parts
            guard index < parts.count else {
                return nil
            }
            
            let part = parts[index]
            
            switch component {
            case .literal(let text):
                if text != part {
                    return nil
                }
            case .parameter(let name):
                params[name] = part
            case .wildcard:
                break
            }
        }
        
        return params
    }
}
