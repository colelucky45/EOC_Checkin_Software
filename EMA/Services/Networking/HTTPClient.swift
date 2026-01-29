//
//  HTTPClient.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Lightweight, async/await-based HTTP client for custom backend integrations.
/// This is intentionally generic so services can build on top of it.
protocol HTTPClientProtocol: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
    func send<T: Decodable>(
        _ request: HTTPRequest,
        decode type: T.Type,
        decoder: JSONDecoder
    ) async throws -> T
}

/// Supported HTTP methods.
enum HTTPMethod: String, Sendable {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
}

/// Simple request container for HTTPClient.
struct HTTPRequest: Sendable {
    var url: URL
    var method: HTTPMethod
    var headers: [String: String]
    var body: Data?
    var timeout: TimeInterval
    
    init(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 30
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}

/// Simple response container for HTTPClient.
struct HTTPResponse: Sendable {
    let data: Data
    let statusCode: Int
    let headers: [AnyHashable: Any]
}

/// Error type used by HTTPClient. Can be mapped into AppError/NetworkError later.
enum HTTPClientError: Error, LocalizedError, Sendable {
    case invalidResponse
    case unacceptableStatusCode(Int)
    case decodingFailed(underlying: Error)
    case underlying(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .unacceptableStatusCode(let code):
            return "The server returned an unacceptable status code: \(code)."
        case .decodingFailed(let underlying):
            return "Failed to decode the response: \(underlying.localizedDescription)"
        case .underlying(let underlying):
            return underlying.localizedDescription
        }
    }
}

/// Default implementation of HTTPClientProtocol.
/// Use `HTTPClient.shared` or inject your own instance for testing.
final class HTTPClient: HTTPClientProtocol, @unchecked Sendable {
    
    static let shared = HTTPClient()
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public API
    
    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.timeout
        
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPClientError.invalidResponse
            }
            
            let statusCode = httpResponse.statusCode
            guard (200..<300).contains(statusCode) else {
                throw HTTPClientError.unacceptableStatusCode(statusCode)
            }
            
            return HTTPResponse(
                data: data,
                statusCode: statusCode,
                headers: httpResponse.allHeaderFields
            )
        } catch {
            throw HTTPClientError.underlying(underlying: error)
        }
    }
    
    func send<T: Decodable>(
        _ request: HTTPRequest,
        decode type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response = try await send(request)
        
        do {
            return try decoder.decode(T.self, from: response.data)
        } catch {
            throw HTTPClientError.decodingFailed(underlying: error)
        }
    }
}
