//
//  Response.swift
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

/// Response object representing an HTTP response
public struct Response {
    public let status: HTTPResponseStatus
    public let headers: [String: String]
    public let body: Data?
    
    /// Initialize a new Response
    public init(status: HTTPResponseStatus = .ok, headers: [String: String] = [:], body: Data? = nil) {
        self.status = status
        self.headers = headers
        self.body = body
    }
    
    /// Create a JSON response
    public static func json<T: Encodable>(_ value: T, status: HTTPResponseStatus = .ok) throws -> Response {
        let data = try JSONEncoder().encode(value)
        return Response(
            status: status,
            headers: ["Content-Type": "application/json"],
            body: data
        )
    }
    
    /// Create a text response
    public static func text(_ string: String, status: HTTPResponseStatus = .ok) -> Response {
        return Response(
            status: status,
            headers: ["Content-Type": "text/plain; charset=utf-8"],
            body: Data(string.utf8)
        )
    }
    
    public static func jsonObject(_ value: Any, status: HTTPResponseStatus = .ok) throws -> Response {
        let data = try JSONSerialization.data(withJSONObject: value)
        return Response(
            status: status,
            headers: ["Content-Type": "application/json"],
            body: data
        )
    }
    
    /// Create an HTML response
    public static func html(_ string: String, status: HTTPResponseStatus = .ok) -> Response {
        return Response(
            status: status,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: Data(string.utf8)
        )
    }
    
    /// Create a redirect response
    public static func redirect(to location: String, permanent: Bool = false) -> Response {
        return Response(
            status: permanent ? .permanentRedirect : .temporaryRedirect,
            headers: ["Location": location]
        )
    }
    
    /// Create a "not found" response
    public static func notFound() -> Response {
        return .text("Not Found", status: .notFound)
    }
    
    /// Create a "bad request" response
    public static func badRequest(_ message: String = "Bad Request") -> Response {
        return .text(message, status: .badRequest)
    }
    
    /// Create an "unauthorized" response
    public static func unauthorized() -> Response {
        return .text("Unauthorized", status: .unauthorized)
    }
    
    /// Create a "forbidden" response
    public static func forbidden() -> Response {
        return .text("Forbidden", status: .forbidden)
    }
    
    /// Create a "no content" response
    public static func noContent() -> Response {
        return Response(status: .noContent)
    }
}
