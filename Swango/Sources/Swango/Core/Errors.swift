//
//  Errors.swift
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
import NIOHTTP1

/// Errors that can occur in the Swango framework
public enum SwangoError: Error {
    case routeNotFound
    case invalidRequest(String)
    case internalError(Error)
    case notAuthenticated
    case permissionDenied
    
    var status: HTTPResponseStatus {
        switch self {
        case .routeNotFound:
            return .notFound
        case .invalidRequest:
            return .badRequest
        case .internalError:
            return .internalServerError
        case .notAuthenticated:
            return .unauthorized
        case .permissionDenied:
            return .forbidden
        }
    }
    
    var message: String {
        switch self {
        case .routeNotFound:
            return "Route not found"
        case .invalidRequest(let message):
            return "Bad request: \(message)"
        case .internalError(let error):
            return "Internal server error: \(error.localizedDescription)"
        case .notAuthenticated:
            return "Authentication required"
        case .permissionDenied:
            return "Permission denied"
        }
    }
}
