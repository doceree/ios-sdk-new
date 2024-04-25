//
//  HcpValidationRequest.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 01/04/24.
//

import Foundation
import os.log

public final class HcpValidationRequest {
    
    // MARK: Properties
    var requestHttpHeaders = RestEntity()
    
    // todo: create a queue of requests and inititate request
    public init() {
    }
    
    internal func getHcpSelfValidation(_ userId: String!, completion: @escaping(_ results: Results) -> Void) {

        var advertisementId: String?
        if let adId = userId {
            advertisementId = adId
        } else {
            advertisementId = getIdentifierForAdvertising()
            if (advertisementId == nil) {
                if #available(iOS 10.0, *) {
                    os_log("Error: Ad Tracking is disabled . Please re-enable it to view ads", log: .default, type: .error)
                } else {
                    // Fallback on earlier versions
                    print("Error: Ad Tracking is disabled . Please re-enable it to view ads")
                }
                return
            }
        }
        
        self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
        
        // query params
        let josnObject: [String : Any] = [
            GetHcpValidation.bundleId.rawValue : Bundle.main.bundleIdentifier!,
            GetHcpValidation.uuid.rawValue : advertisementId as Any,
        ]

        let body = josnObject //httpBodyParameters.allValues()
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        var components = URLComponents()
        components.scheme = "https"
        components.host = getDataCollectionHost(type: DocereeMobileAds.shared().getEnvironment())
        components.path = getPath(methodName: Methods.HcpValidation, type: DocereeMobileAds.shared().getEnvironment())
        let collectDataEndPoint: URL = components.url!
        var request: URLRequest = URLRequest(url: collectDataEndPoint)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // set headers
        for header in requestHttpHeaders.allValues() {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        request.httpMethod = HttpMethod.post.rawValue
        
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            return
        }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard data != nil else { return }
            let urlResponse = response as! HTTPURLResponse

            if urlResponse.statusCode == 200 {
                do {
                    let decode = try JSONDecoder().decode(HcpValidation.self, from: data!)
                    print("hcpValidationData: ",decode)
                    if decode.code != 200 {
                        completion(Results(withData: nil, response: response as? HTTPURLResponse, error: HcpRequestError.apiFailed))
                        return
                    }
                    completion(Results(withData: data, response: response as? HTTPURLResponse, error: nil))
                } catch {
                    completion(Results(withData: nil, response: response as? HTTPURLResponse, error: HcpRequestError.parsingError))
                }
            } else {
                completion(Results(withData: nil, response: response as? HTTPURLResponse, error: HcpRequestError.apiFailed))
            }
        }
        task.resume()

    }

}


//do {
//    // Check for network errors
//    if let error = error {
//        throw HcpRequestError.networkError(error)
//    }
//    // Check for HTTP errors
//    guard let httpResponse = response as? HTTPURLResponse else {
//        throw HcpRequestError.httpError(0)
//    }
//    if !(200..<300).contains(httpResponse.statusCode) {
//        throw HcpRequestError.httpError(httpResponse.statusCode)
//    }
//    // Parse response data
//    let decode = try JSONDecoder().decode(HcpValidation.self, from: data!)
//    completion(Results(withData: data, response: response as? HTTPURLResponse, error: nil))
//} catch {
//    // Handle API errors
//    switch error {
//    case let APIError.networkError(networkError):
//        completion(Results(withData: nil, response: response as? HTTPURLResponse, error: HcpRequestError.networkError(networkError as! Error)))
//        break
//    case let APIError.httpError(statusCode):
//        completion(Results(withData: nil, response: response as? HTTPURLResponse, error: HcpRequestError.httpError(statusCode)))
//        break
//    case let APIError.serializationError(serializationError):
//        completion(Results(withData: nil, response: response as? HTTPURLResponse, error: HcpRequestError.serializationError(serializationError)))
//        break
//    default:
//        completion(Results(withData: nil, response: response as? HTTPURLResponse, error: HcpRequestError.serializationError(error)))
//        break
//    }
//}
