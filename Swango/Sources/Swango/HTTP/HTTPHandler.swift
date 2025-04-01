//
//  HTTPHandler.swift
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
import NIO
import NIOHTTP1

/// Channel handler that processes HTTP requests
class HTTPHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    private let router: Router
    private let middlewares: [Middleware]
    private var requestHead: HTTPRequestHead?
    private var requestBody = Data()
    
    init(router: Router, middlewares: [Middleware]) {
        self.router = router
        self.middlewares = middlewares
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = unwrapInboundIn(data)
        
        switch requestPart {
        case .head(let head):
            requestHead = head
            
        case .body(let buffer):
            var data = Data()
            let byteCount = buffer.readableBytes
            if byteCount > 0 {
                if let bytes = buffer.getBytes(at: buffer.readerIndex, length: byteCount) {
                    data = Data(bytes)
                }
            }
            requestBody.append(data)
            
        case .end:
            guard let head = requestHead else {
                respondWithError(context: context, error: SwangoError.invalidRequest("Invalid HTTP request"))
                return
            }
            
            let headers = Dictionary(head.headers.map { ($0.name, $0.value) }, uniquingKeysWith: { first, _ in first })
            
            let request = Request(
                method: head.method,
                path: head.uri,
                headers: headers,
                body: requestBody.isEmpty ? nil : requestBody
            )
            
            handleRequest(request, context: context)
            
            // Reset state for the next request
            requestHead = nil
            requestBody = Data()
        }
    }
    
    private func handleRequest(_ request: Request, context: ChannelHandlerContext) {
        do {
            guard let (handler, params) = router.findHandler(for: request) else {
                throw SwangoError.routeNotFound
            }
            
            // Create a new request with path parameters
            var requestWithParams = request
            requestWithParams.pathParameters = params
            
            // Apply middlewares
            let finalHandler = applyMiddlewares(to: requestWithParams, handler: handler)
            
            let response = try finalHandler(requestWithParams)
            sendResponse(response, context: context)
            
        } catch {
            respondWithError(context: context, error: error)
        }
    }
    
    private func applyMiddlewares(to request: Request, handler: @escaping RouteHandler) -> RouteHandler {
        var finalHandler = handler
        
        // Apply middlewares in reverse order
        for middleware in middlewares.reversed() {
            let currentHandler = finalHandler
            finalHandler = { request in
                try middleware(request, currentHandler)
            }
        }
        
        return finalHandler
    }
    
    private func sendResponse(_ response: Response, context: ChannelHandlerContext) {
        var headers = HTTPHeaders()
        response.headers.forEach { key, value in
            headers.add(name: key, value: value)
        }
        
        let responseHead = HTTPResponseHead(
            version: .init(major: 1, minor: 1),
            status: response.status,
            headers: headers
        )
        
        context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
        
        if let body = response.body, !body.isEmpty {
            var buffer = context.channel.allocator.buffer(capacity: body.count)
            buffer.writeBytes(body)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        }
        
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }
    
    private func respondWithError(context: ChannelHandlerContext, error: Error) {
        let response: Response
        
        switch error {
        case let swangoError as SwangoError:
            response = Response.text(swangoError.message, status: swangoError.status)
        default:
            response = Response.text("Internal Server Error", status: .internalServerError)
        }
        
        sendResponse(response, context: context)
    }
}
