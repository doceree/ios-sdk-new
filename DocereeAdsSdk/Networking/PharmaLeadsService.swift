//
//  PharmaLeadsService.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 18/08/23.
//

import Foundation

public final class PharmaLeadsService {
    
    // MARK: Properties
    var requestHttpHeaders = RestEntity()
    
    init() {
        
    }
    
    func sendPharmaLeads(_ responseData: AdResponse?, _ size: String, _ userInput: [String : Any]) {

        self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
        
        // query params
        let josnObject: [String : Any] = [
            PharmaLeads.date.rawValue : userInput["date"] as Any,
            PharmaLeads.time.rawValue : userInput["time"] as Any,
            PharmaLeads.name.rawValue : userInput["name"] as Any,
            PharmaLeads.mobile.rawValue : userInput["mobile"] as Any,
            PharmaLeads.email.rawValue : userInput["email"] as Any,
            PharmaLeads.address.rawValue : userInput["address"] as Any,
            PharmaLeads.country.rawValue : userInput["country"] as Any,
            PharmaLeads.zipcode.rawValue : userInput["zip"] as Any,
            PharmaLeads.cta.rawValue : userInput["cta"] as Any,
            PharmaLeads.isNewPlatformUid.rawValue : responseData?.isNewPlatformUid() as Any,
            PharmaLeads.subcampaignId.rawValue : responseData?.subcampaignId() as Any,
            PharmaLeads.creativeId.rawValue : responseData?.crId as Any,
            PharmaLeads.advertiserId.rawValue : responseData?.aId as Any,
            PharmaLeads.brandId.rawValue : responseData?.bId as Any,
            PharmaLeads.bidRequestId.rawValue : responseData?.guid as Any,
            PharmaLeads.dimension.rawValue : size,
            PharmaLeads.codeSnippetId.rawValue : responseData?.DIVID as Any,
            PharmaLeads.platformUid.rawValue : responseData?.platformUID as Any
        ]

        let body = josnObject //httpBodyParameters.allValues()
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        var components = URLComponents()
        components.scheme = "https"
        components.host = getDocTrackerHost(type: DocereeMobileAds.shared().getEnvironment())
        components.path = getPath(methodName: Methods.PharmaLead, type: DocereeMobileAds.shared().getEnvironment())
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
            print(urlResponse.statusCode)
        }
        task.resume()

    }
}
