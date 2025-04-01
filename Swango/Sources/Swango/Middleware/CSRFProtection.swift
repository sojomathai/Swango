//
//  File.swift
//  Swango
/*  Created by sojo
 
## License

This project is available under a dual license:

- **GNU Affero General Public License v3.0 (AGPL-3.0)** for open source projects
- **Commercial License** for enterprise and commercial use

If you are using this software in a commercial or enterprise context, please contact us at info@techarm.ca to obtain a commercial license.
*/
import Foundation


/// CSRF token middleware
public class CSRFProtection {
    private let tokenName: String
    private let headerName: String
    private var tokens: [String: Date] = [:]
    
    public init(tokenName: String = "csrftoken", headerName: String = "X-CSRF-Token") {
        self.tokenName = tokenName
        self.headerName = headerName
    }
    
    /// Create middleware for CSRF protection
    public func middleware() -> Middleware {
        return { request, next in
            // Skip CSRF check for safe methods
            if ["GET", "HEAD", "OPTIONS", "TRACE"].contains(request.method.rawValue) {
                return try next(request)
            }
            
            // Check for CSRF token
            guard let session = request.session else {
                throw SwangoError.invalidRequest("No session available")
            }
            
            let csrfToken = request.headers[self.headerName] ?? ""
            guard let storedToken: String = session.get(self.tokenName),
                  !storedToken.isEmpty,
                  csrfToken == storedToken else {
                throw SwangoError.invalidRequest("CSRF token missing or invalid")
            }
            
            return try next(request)
        }
    }
    
    /// Generate a new CSRF token
    public func generateToken() -> String {
        let token = UUID().uuidString
        tokens[token] = Date()
        
        // Clean up expired tokens (older than 24 hours)
        let now = Date()
        tokens = tokens.filter { _, date in
            return now.timeIntervalSince(date) < 86400 // 24 hours
        }
        
        return token
    }
}
