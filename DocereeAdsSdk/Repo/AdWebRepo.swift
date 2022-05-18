
import Foundation
import Combine

// MARK: Base class
class AdWebRepo {
    static let shared = AdWebRepo()
    private let session: URLSession
    
    init(session: URLSession = URLSession.shared) {
        self.session = session
    }
}

// MARK: Supported endpoints
extension AdWebRepo {
    enum AdWebRepoApi {
        case getAdImage(AdRequest)
        case sendImpression
        case blockRequest(AdBlockRequest)
    }
}

// MARK: Endpoint configuration
extension AdWebRepo.AdWebRepoApi: APICall {
    var path: String {
        switch self {
        case let .getAdImage(request):
            return "/v1/adrequest?" +
            "id=\(request.id)&" +
            "size=\(request.size)&" +
            "platformType=\(request.platformType)&appKey=\(request.appKey)&loggedInUser=\(request.loggedInUser)"
        
        case .sendImpression:
            return ""
        case .blockRequest:
            return "/saveadblockinfo"
        }
    }
    
    var method: String {
        switch self {
        case .getAdImage, .sendImpression:
            return HTTPMethod.get
        case .blockRequest:
            return HTTPMethod.post
        }
    }
    
    var headers: [String: String]? {
        return [HTTPHeaderKey.contentType: HTTPHeaderValue.applicationJson,
                Header.header_user_agent.rawValue: UAString.init().UAString()]
    }
    
    func body() throws -> Data? {
        switch self {
        case .getAdImage, .sendImpression:
            return nil
        case let .blockRequest(request):
            do {
                let data = try JSONEncoder().encode(request)
                return data
            } catch {
                return nil
            }
        }
    }
}

// MARK: Protocol
protocol AdWebRepoProtocol {
    func getAdImage(request: AdRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
    func sendAdImpression(request: String) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
    func sendAdBlockRequest(request: AdBlockRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

// MARK: Implementation
extension AdWebRepo: AdWebRepoProtocol {

    func getAdImage(request: AdRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
         let apiRequest = try? AdWebRepoApi.getAdImage(request)
             .urlRequest(baseURL: "https://dev-bidder.doceree.com")
        return session.dataTaskPublisher(for: apiRequest!)
                .eraseToAnyPublisher()
    }
    
    func sendAdImpression(request: String) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        let apiRequest = (try? AdWebRepoApi.sendImpression
            .urlRequest(baseURL: request)) ?? opetionalRequest()
        return session.dataTaskPublisher(for: apiRequest)
            .eraseToAnyPublisher()
    }
    
    func sendAdBlockRequest(request: AdBlockRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        let apiRequest = (try? AdWebRepoApi.blockRequest(request)
            .urlRequest(baseURL: "https://dev-tracking.doceree.com")) ?? opetionalRequest()
        return session.dataTaskPublisher(for: apiRequest)
            .eraseToAnyPublisher()
    }

    
    // Optional request
    func opetionalRequest() -> URLRequest {
        let url = URL(string: "")!
        let request = URLRequest(url: url)
        return request
    }
}
