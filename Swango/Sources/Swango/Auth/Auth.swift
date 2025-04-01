//
//  Auth.swift
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

/// Protocol for user authentication
public protocol Authenticatable: Model {
    /// Username field
    var username: String { get }
    
    /// Password field (hashed)
    var password: String { get }
    
    /// Check if the password matches
    func checkPassword(_ password: String) -> Bool
    
    /// Hash a password
    static func hashPassword(_ password: String) -> String
}

/// Authentication service
public class AuthService {
    private let db: Database
    
    public init(database: Database) {
        self.db = database
    }
    
    /// Authenticate a user
    public func authenticate<T: Authenticatable>(username: String, password: String) throws -> T? {
        let sql = "SELECT * FROM \(T.tableName) WHERE username = ? LIMIT 1;"
        let results = try db.query(sql, parameters: [username])
        
        guard let userRow = results.first else {
            return nil
        }
        
        do {
            let user = try T(from: userRow)
            return user.checkPassword(password) ? user : nil
        } catch {
            return nil
        }
    }
    
    /// Authentication middleware that requires a user of type T
    public func authMiddleware<T: Authenticatable>(_ userType: T.Type, redirectTo: String? = nil) -> Middleware {
        return { [weak self] request, next in
            guard let self = self else {
                throw SwangoError.internalError(NSError(domain: "Swango", code: 500, userInfo: [NSLocalizedDescriptionKey: "Auth service not available"]))
            }
            
            // Check if user is already authenticated
            if let session = request.session, let userId = session.get("user_id") as String? {
                // Verify the user still exists and is of the correct type
                do {
                    let sql = "SELECT * FROM \(T.tableName) WHERE id = ? LIMIT 1;"
                    let results = try self.db.query(sql, parameters: [userId])
                    
                    if let userRow = results.first {
                        _ = try T(from: userRow) // Ensure we can parse the user as type T
                        return try next(request)
                    }
                } catch {
                    // If verification fails, we'll proceed to re-authenticate
                }
            }
            
            // Get credentials from Authorization header
            if let authHeader = request.headers["Authorization"], authHeader.hasPrefix("Basic ") {
                let base64Credentials = authHeader.dropFirst(6)
                if let credentialsData = Data(base64Encoded: String(base64Credentials)),
                   let credentials = String(data: credentialsData, encoding: .utf8) {
                    let parts = credentials.split(separator: ":")
                    if parts.count == 2 {
                        let username = String(parts[0])
                        let password = String(parts[1])
                        
                        if let user: T = try self.authenticate(username: username, password: password) {
                            // Create a new request with authenticated user in session
                            var newRequest = request
                            var session = newRequest.session ?? Session(id: UUID().uuidString)
                            session.set("user_id", value: user.toDictionary()["id"] as? String ?? "")
                            session.set("username", value: user.username)
                            newRequest.session = session
                            
                            return try next(newRequest)
                        }
                    }
                }
            }
            
            // User is not authenticated
            if let redirectPath = redirectTo {
                return Response.redirect(to: redirectPath)
            } else {
                throw SwangoError.notAuthenticated
            }
        }
    }
}

/// Permission checking protocol
public protocol PermissionChecker {
    /// Check if a request has permission
    func hasPermission(request: Request) -> Bool
}

/// Permission middleware
public func permissionMiddleware(_ checker: PermissionChecker) -> Middleware {
    return { request, next in
        guard checker.hasPermission(request: request) else {
            throw SwangoError.permissionDenied
        }
        
        return try next(request)
    }
}
