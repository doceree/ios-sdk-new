
import Foundation

public enum DocereeAdRequestError: String, Error {
    case failedToCreateRequest
    case adNotFound = "Ad not found"
}

public enum HcpRequestError: String, Error {
    case apiFailed = "Api Failed"
    case parsingError = "Parsing Error"
    case noScriptFound = "No script found"
}

//public enum HcpRequestError: Error {
//    case networkError(Error)
//    case httpError(Int)
//    case serializationError(Error)
//    // Add more error cases as needed
//}
