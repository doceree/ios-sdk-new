
import Foundation

public protocol APICall {
	var path: String { get }
	var method: String { get }
	var headers: [String: String]? { get }
	func body() throws -> Data?
}

public extension APICall {
    func urlRequest(baseURL: String) throws -> URLRequest {
		guard let url = URL(string: baseURL + path) else {
			throw APIError.url(description: "Invalid URL")
		}
		var request = URLRequest(url: url)
		request.httpMethod = method
		request.allHTTPHeaderFields = headers
        request.setValue(HTTPHeaderValue.platformInfo, forHTTPHeaderField: HTTPHeaderKey.platform)
		request.httpBody = try body()
		return request
	}
}

public enum APIError: Error, Equatable {
	case parsing(description: String)
	case network(description: String)
	case url(description: String)
}

enum APICallError: LocalizedError, Equatable {
    case noInternet
    case invalidResponse
    case statusCode(Int)
    case invalidData
    case invalidRequest
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case urlSessionFailed(_ error: URLError)
    case invalidUrl
    case encoding
    case decoding
    case unknownError
    case error4xx(_ code: Int)
    case error5xx(_ code: Int)
}
