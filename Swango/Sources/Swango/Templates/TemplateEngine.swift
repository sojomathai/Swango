//
//  TemplateEngine.swift
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

/// Simple template rendering engine
public class TemplateEngine {
    private let templatesDirectory: String
    
    public init(directory: String) {
        self.templatesDirectory = directory
    }
    
    /// Render a template with context
    public func render(_ template: String, context: [String: Any] = [:]) throws -> String {
        let path = "\(templatesDirectory)/\(template)"
        
        guard let templateString = try? String(contentsOfFile: path, encoding: .utf8) else {
            throw SwangoError.invalidRequest("Template not found: \(template)")
        }
        
        var result = templateString
        
        // Simple variable substitution
        for (key, value) in context {
            result = result.replacingOccurrences(of: "{{ \(key) }}", with: "\(value)")
        }
        
        // Simple conditional blocks
        let ifPattern = try NSRegularExpression(pattern: "{% if ([^%]+) %}(.*?){% endif %}", options: [.dotMatchesLineSeparators])
        let ifMatches = ifPattern.matches(in: result, options: [], range: NSRange(location: 0, length: result.utf16.count))
        
        for match in ifMatches.reversed() {
            guard
                let conditionRange = Range(match.range(at: 1), in: result),
                let contentRange = Range(match.range(at: 2), in: result),
                let blockRange = Range(match.range, in: result)
            else { continue }
            
            let condition = String(result[conditionRange])
            let content = String(result[contentRange])
            
            // Very simple condition evaluation
            let shouldInclude: Bool
            if let boolValue = context[condition] as? Bool {
                shouldInclude = boolValue
            } else if let value = context[condition], !(value is NSNull) {
                shouldInclude = true
            } else {
                shouldInclude = false
            }
            
            result = result.replacingCharacters(in: blockRange, with: shouldInclude ? content : "")
        }
        
        // Simple for loops
        let forPattern = try NSRegularExpression(pattern: "{% for ([^%]+) in ([^%]+) %}(.*?){% endfor %}", options: [.dotMatchesLineSeparators])
        let forMatches = forPattern.matches(in: result, options: [], range: NSRange(location: 0, length: result.utf16.count))
        
        for match in forMatches.reversed() {
            guard
                let varRange = Range(match.range(at: 1), in: result),
                let listRange = Range(match.range(at: 2), in: result),
                let contentRange = Range(match.range(at: 3), in: result),
                let blockRange = Range(match.range, in: result)
            else { continue }
            
            let varName = String(result[varRange])
            let listName = String(result[listRange])
            let content = String(result[contentRange])
            
            guard let list = context[listName] as? [Any] else {
                result = result.replacingCharacters(in: blockRange, with: "")
                continue
            }
            
            var replacement = ""
            for item in list {
                var itemContent = content
                itemContent = itemContent.replacingOccurrences(of: "{{ \(varName) }}", with: "\(item)")
                replacement += itemContent
            }
            
            result = result.replacingCharacters(in: blockRange, with: replacement)
        }
        
        return result
    }
}
