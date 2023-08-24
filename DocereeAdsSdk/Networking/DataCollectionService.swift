//
//  DataCollectionService.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 18/08/23.
//

import Foundation
import os.log

final class DataCollectionService {
    
    // MARK: Properties
    var requestHttpHeaders = RestEntity()
    
    init() {
        
    }
    
    func sendDataCollection(screenPath: String?, editorialTags: [String]?, gps: String?, platformData: String?, event: [String : String]?) {
        if !DocereeMobileAds.collectDataStatus {
            return
        }
        var advertisementId: String?
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
        
        self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
        
        // query params
        let josnObject: [String : Any] = [
            CollectDataService.advertisingId.rawValue : advertisementId as Any,
            CollectDataService.bundleId.rawValue : Bundle.main.bundleIdentifier!,
            CollectDataService.platformId.rawValue : platformId,
            CollectDataService.hcpId.rawValue : DocereeMobileAds.shared().getProfile()?.mciRegistrationNumber as Any,
            CollectDataService.dataSource.rawValue : dataSource,
            CollectDataService.screenPath.rawValue : screenPath as Any,
            CollectDataService.editorialTags.rawValue : editorialTags as Any,
            CollectDataService.localTimestamp.rawValue : Date.getFormattedDate(),
            CollectDataService.installedApps.rawValue : [""],
            CollectDataService.privateMode.rawValue : 0,
            CollectDataService.gps.rawValue : gps as Any,
            CollectDataService.event.rawValue : event as Any,
            CollectDataService.platformData.rawValue : platformData as Any,
            CollectDataService.partnerData.rawValue : getParnerData(),
        ]

        let body = josnObject //httpBodyParameters.allValues()
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        var components = URLComponents()
        components.scheme = "https"
        components.host = getDataCollectionHost(type: DocereeMobileAds.shared().getEnvironment())
        components.path = getPath(methodName: Methods.CollectData, type: DocereeMobileAds.shared().getEnvironment())
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
