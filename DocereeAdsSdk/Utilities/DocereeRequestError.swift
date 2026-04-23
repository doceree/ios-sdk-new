
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
    /// URLSession returned a non-HTTP URL response for an ad request.
    case nonHTTPResponse
    /// Ad bidder returned a non-success HTTP status (after retries for transient 5xx, if any).
    case httpUnsuccessful
}

public enum HcpRequestError: String, Error {
    case apiFailed = "Api Failed"
    case parsingError = "Parsing Error"
    case noScriptFound = "No script found"
}
