//
//  StaticFiles.swift
//  Swango
/*  Created by sojo
 
## License

This project is available under a dual license:

- **GNU Affero General Public License v3.0 (AGPL-3.0)** for open source projects
- **Commercial License** for enterprise and commercial use

If you are using this software in a commercial or enterprise context, please contact us at info@techarm.ca to obtain a commercial license.
*/

import Foundation

/// Static file handler
public class StaticFiles {
    private let directory: String
    private let urlPrefix: String
    
    public init(directory: String, urlPrefix: String = "/static") {
        self.directory = directory
        self.urlPrefix = urlPrefix
    }
    
    /// Create middleware for serving static files
    public func middleware() -> Middleware {
        return { request, next in
            // Check if the request is for a static file
            if request.path.hasPrefix(self.urlPrefix) {
                // Get the file path
                let filePath = request.path.dropFirst(self.urlPrefix.count)
                let fullPath = "\(self.directory)/\(filePath)"
                
                // Try to read the file
                if let fileData = try? Data(contentsOf: URL(fileURLWithPath: fullPath)) {
                    // Determine content type
                    let contentType: String
                    if fullPath.hasSuffix(".css") {
                        contentType = "text/css"
                    } else if fullPath.hasSuffix(".js") {
                        contentType = "application/javascript"
                    } else if fullPath.hasSuffix(".html") {
                        contentType = "text/html"
                    } else if fullPath.hasSuffix(".png") {
                        contentType = "image/png"
                    } else if fullPath.hasSuffix(".jpg") || fullPath.hasSuffix(".jpeg") {
                        contentType = "image/jpeg"
                    } else if fullPath.hasSuffix(".gif") {
                        contentType = "image/gif"
                    } else if fullPath.hasSuffix(".svg") {
                        contentType = "image/svg+xml"
                    } else {
                        contentType = "application/octet-stream"
                    }
                    
                    return Response(
                        status: .ok,
                        headers: ["Content-Type": contentType],
                        body: fileData
                    )
                }
            }
            
            // Not a static file, continue to the next handler
            return try next(request)
        }
    }
}
