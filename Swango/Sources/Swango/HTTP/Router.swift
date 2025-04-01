//
//  Router.swift
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

/// A type alias for route handlers
public typealias RouteHandler = (Request) throws -> Response

/// Middleware function type
public typealias Middleware = (Request, @escaping RouteHandler) throws -> Response

/// Router class responsible for managing routes
class Router {
    private struct RouteInfo {
        let method: HTTPMethod
        let pathPattern: PathPattern
        let handler: RouteHandler
    }
    
    private var routes: [RouteInfo] = []
    
    /// Add a route to the router
    func addRoute(method: HTTPMethod, path: String, handler: @escaping RouteHandler) {
        let pathPattern = PathPattern(pattern: path)
        routes.append(RouteInfo(method: method, pathPattern: pathPattern, handler: handler))
    }
    
    /// Find a handler for a given request
    func findHandler(for request: Request) -> (RouteHandler, [String: String])? {
        for route in routes {
            if route.method == request.method {
                if let params = route.pathPattern.match(path: request.path) {
                    return (route.handler, params)
                }
            }
        }
        return nil
    }
}
