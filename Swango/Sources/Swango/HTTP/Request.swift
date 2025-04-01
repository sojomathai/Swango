//
//  Request.swift
//  Swango
/*  Created by sojo
 
## License

This project is available under a dual license:

- **GNU Affero General Public License v3.0 (AGPL-3.0)** for open source projects
- **Commercial License** for enterprise and commercial use

If you are using this software in a commercial or enterprise context, please contact us at info@techarm.ca to obtain a commercial license.
*/

import Foundation
import NIOHTTP1

/// Request object representing an HTTP request
public struct Request {
    public let method: HTTPMethod
    public let path: String
    public let headers: [String: String]
    public let body: Data?
    public var pathParameters: [String: String]
    public var queryParameters: [String: String]
    public var session: Session?
    
    /// Initialize a new Request
    init(method: HTTPMethod, path: String, headers: [String: String], body: Data?, pathParameters: [String: String] = [:]) {
        self.method = method
        
        // Split path and query string
        let components = path.split(separator: "?", maxSplits: 1)
        self.path = String(components[0])
        
        self.headers = headers
        self.body = body
        self.pathParameters = pathParameters
        
        // Parse query parameters
        var queryParams: [String: String] = [:]
        if components.count > 1 {
            let queryString = components[1]
            let pairs = queryString.split(separator: "&")
            for pair in pairs {
                let keyValue = pair.split(separator: "=", maxSplits: 1).map { String($0) }
                if keyValue.count == 2 {
                    queryParams[keyValue[0]] = keyValue[1]
                }
            }
        }
        self.queryParameters = queryParams
    }
    
    /// Decode the request body as JSON
    public func json<T: Decodable>() throws -> T {
        guard let body = body else {
            throw SwangoError.invalidRequest("Missing request body")
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: body)
        } catch {
            throw SwangoError.invalidRequest("Invalid JSON: \(error.localizedDescription)")
        }
    }
    
    /// Get a path parameter by name
    public func param(_ name: String) -> String? {
        return pathParameters[name]
    }
    
    /// Get a query parameter by name
    public func query(_ name: String) -> String? {
        return queryParameters[name]
    }
}
