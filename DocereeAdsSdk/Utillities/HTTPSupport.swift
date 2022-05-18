
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
