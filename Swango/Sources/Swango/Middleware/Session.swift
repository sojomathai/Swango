//
//  Session.swift
//  Swango
/*  Created by sojo
 
## License

This project is available under a dual license:

- **GNU Affero General Public License v3.0 (AGPL-3.0)** for open source projects
- **Commercial License** for enterprise and commercial use

If you are using this software in a commercial or enterprise context, please contact us at info@techarm.ca to obtain a commercial license.
*/

import Foundation

/// Session struct for managing user sessions
public struct Session {
    public var id: String
    public var data: [String: Any]
    
    public init(id: String, data: [String: Any] = [:]) {
        self.id = id
        self.data = data
    }
    
    public func get<T>(_ key: String) -> T? {
        return data[key] as? T
    }
    
    public mutating func set<T>(_ key: String, value: T) {
        data[key] = value
    }
    
    public mutating func remove(_ key: String) {
        data.removeValue(forKey: key)
    }
    
    public mutating func clear() {
        data.removeAll()
    }
}

/// Session middleware for managing user sessions
public class SessionMiddleware {
    private var storage: [String: [String: Any]] = [:]
    private let cookieName: String
    
    public init(cookieName: String = "swango_session") {
        self.cookieName = cookieName
    }
    
    public func middleware() -> Middleware {
        return { request, next in
            // Get or create session ID
            let sessionId = request.headers["Cookie"]?
                .split(separator: ";")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first(where: { $0.hasPrefix("\(self.cookieName)=") })?
                .split(separator: "=", maxSplits: 1)
                .last
                .map { String($0) }
                ?? UUID().uuidString
            
            // Get or create session data
            let sessionData = self.storage[sessionId] ?? [:]
            var session = Session(id: sessionId, data: sessionData)
            
            // Create a new request with session
            var requestWithSession = request
            requestWithSession.session = session
            
            // Execute the next handler
            let response = try next(requestWithSession)
            
            // Save session data
            self.storage[sessionId] = session.data
            
            // Set session cookie in response
            var headers = response.headers
            headers["Set-Cookie"] = "\(self.cookieName)=\(sessionId); Path=/; HttpOnly"
            
            return Response(
                status: response.status,
                headers: headers,
                body: response.body
            )
        }
    }
}
