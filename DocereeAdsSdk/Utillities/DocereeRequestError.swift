
import Foundation

public enum DocereeAdRequestError: String, Error {
    case failedToCreateRequest
    case adNotFound = "Ad not found"
    case invalidAppKey
    case adTrackingDisabled
    case invalidUserProfile
    case adServerReturnedError
    case invalidURL
    case invalidRequest
    case invalidResponse
}

public enum HcpRequestError: String, Error {
    case apiFailed = "Api Failed"
    case parsingError = "Parsing Error"
    case noScriptFound = "No script found"
}
