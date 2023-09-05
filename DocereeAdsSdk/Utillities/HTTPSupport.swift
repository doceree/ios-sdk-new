
import Foundation

struct HTTPMethod {
	static let get = "GET"
	static let post = "POST"
	static let put = "PUT"
    static let delete = "DELETE"
}

struct HTTPHeaderKey {
	static let contentType = "Content-Type"
	static let authorization = "Authorization"
    static let platform = "Platform"
}

struct HTTPHeaderValue {
	static let applicationJson = "application/json"
}

extension HTTPHeaderValue {
    static var platformInfo: String {
        return "iOS 13.0"
//        return UIApplication.osName + ";" + UIApplication.buildVersion
    }

}

enum HttpMethod: String {
    case get
    case post
}

func getHost(type: EnvironmentType) -> String? {
    switch type {
    case .Dev:
        return "dev-bidder.doceree.com"
    case .Local:
        return "10.0.3.2"
    case .Qa:
        return "qa-ad-test.doceree.com"
    case .Prod:
        return "dai.doceree.com"
    }
}

func getDocTrackerHost(type: EnvironmentType) -> String? {
    switch type {
    case .Dev:
        return "dev-tracking.doceree.com"
    case .Local:
        return "10.0.3.2"
    case .Qa:
        return "qa-ad-test.doceree.com"
    case .Prod:
        return "dai.doceree.com"
    }
}

func getDataCollectionHost(type: EnvironmentType) -> String? {
    switch type {
    case .Dev:
        return "qa-identity.doceree.com"
    case .Local:
        return "10.0.3.2"
    case .Qa:
        return "qa-identity.doceree.com"
    case .Prod:
        return "dai.doceree.com"
    }
}

enum Methods{
    case GetImage
    case AdBlock
    case CollectData
}

func getPath(methodName: Methods, type: EnvironmentType = .Dev) -> String {
    switch methodName{
    case .GetImage:
        return "/drs/quest"
    case .AdBlock:
        return "/drs/saveAdBlockInfo"
    case .CollectData:
        switch type {
        case .Dev, .Local, .Qa:
            return "/curator"
        case .Prod:
            return "/dop/curator"
        }
    }
}
