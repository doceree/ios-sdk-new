//
//  AdBlockService.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 18/08/23.
//

import Foundation

final class AdBlockService {
    
    // MARK: Properties
    var requestHttpHeaders = RestEntity()
    
    init() {
        
    }
    
    func sendAdBlockRequest(_ advertiserCampID: String?, _ blockLevel: String?, _ platformUid: String?, _ publisherACSID: String?){
        if ((advertiserCampID ?? "").isEmpty || (blockLevel ?? "").isEmpty || (platformUid ?? "").isEmpty || (publisherACSID ?? "").isEmpty) {
            return
        }
        let ua: String = UAString.init().UAString()
        // headers
        self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
        self.requestHttpHeaders.add(value: UAString.init().UAString(), forKey: Header.header_user_agent.rawValue)
        
        // query params
        var httpBodyParameters = RestEntity()
        httpBodyParameters.add(value: advertiserCampID!, forKey: AdBlock.advertiserCampID.rawValue)
        httpBodyParameters.add(value: blockLevel!, forKey: AdBlock.blockLevel.rawValue)
        httpBodyParameters.add(value: platformUid!, forKey: AdBlock.platformUid.rawValue)
        httpBodyParameters.add(value: publisherACSID!, forKey: AdBlock.publisherACSID.rawValue)
        
        let body = httpBodyParameters.allValues()
//        print("AdBlock request passed is \(body)")
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        var components = URLComponents()
        components.scheme = "https"
        components.host = getDocTrackerHost(type: DocereeMobileAds.shared().getEnvironment())
        components.path = getPath(methodName: Methods.AdBlock)
        let adBlockEndPoint: URL = components.url!
        var request: URLRequest = URLRequest(url: adBlockEndPoint)
        request.setValue(ua, forHTTPHeaderField: Header.header_user_agent.rawValue)
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
        } catch{
            return
        }
        let task = session.dataTask(with: request){(data, response, error) in
            guard data != nil else { return }
            let urlResponse = response as! HTTPURLResponse
            print("Test: Send Block")
            print(urlResponse.statusCode)
        }
        task.resume()
    }

}
