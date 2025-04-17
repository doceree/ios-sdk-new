//
//  DocereeAdRequest.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 16/05/22.
//


import Foundation
import UIKit
import Combine
import os.log

public final class DocereeAdRequest {

    // MARK: Properties
    var requestHttpHeaders = RestEntity()
    var isVendorId: Bool = false
    
    // todo: create a queue of requests and inititate request
    public init() {
    }
    
    // MARK: Properties
    private var isPlatformUidPresent: Bool = false
    
    private static var sharedObject: DocereeAdRequest = {
        let docereeAdRequest = DocereeAdRequest()
        return docereeAdRequest
    }()
    
    public class func shared() -> DocereeAdRequest {
        return sharedObject
    }
    
    // MARK: internal methods
    internal func requestAd(_ userId: String!, _ adUnitId: String!, _ size: String!, completion: @escaping(_ results: Results,
                                                                                        _ isRichMediaAd: Bool) -> Void) {
       
        guard let appKey = DocereeMobileAds().loadDocereeIdentifier(from: DocereeAdsIdArchivingUrl) else {
            // Handle missing key
            return
        }

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
        if advertisementId != nil {
            guard let loggedInUser = DocereeMobileAds.shared().getProfile() else {
                print("Error: Not found profile data")
                return
            }

            //header
            self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
            self.requestHttpHeaders.add(value: UAString.init().UAString(), forKey: HeaderEnum.header_user_agent.rawValue)
            self.requestHttpHeaders.add(value: advertisementId!, forKey: HeaderEnum.header_advertising_id.rawValue)
            self.requestHttpHeaders.add(value: self.isVendorId ? "1" : "0", forKey: HeaderEnum.is_vendor_id.rawValue)
            self.requestHttpHeaders.add(value: DocereeMobileAds.trackingStatus, forKey: HeaderEnum.header_is_ad_tracking_enabled.rawValue)
            self.requestHttpHeaders.add(value: Bundle.main.displayName!, forKey: HeaderEnum.header_app_name.rawValue)
            self.requestHttpHeaders.add(value: Bundle.main.bundleIdentifier!, forKey: HeaderEnum.header_app_bundle.rawValue)
            self.requestHttpHeaders.add(value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String, forKey: HeaderEnum.header_app_version.rawValue)
            self.requestHttpHeaders.add(value: sdkVersion, forKey: HeaderEnum.header_lib_version.rawValue)

            // query params
            let josnObject: [String : Any] = [
                QueryParamsForAdRequest.appKey.rawValue : appKey as Any,
                QueryParamsForAdRequest.userId.rawValue : advertisementId as Any,
                QueryParamsForAdRequest.email.rawValue : loggedInUser.email ?? "",
                QueryParamsForAdRequest.firstName.rawValue : loggedInUser.firstName ?? "",
                QueryParamsForAdRequest.lastName.rawValue : loggedInUser.lastName ?? "",
                QueryParamsForAdRequest.specialization.rawValue : loggedInUser.specialization ?? "",
                QueryParamsForAdRequest.hcpId.rawValue : loggedInUser.hcpId ?? "",
                QueryParamsForAdRequest.hashedHcpId.rawValue : loggedInUser.hashedHcpId ?? "",
                QueryParamsForAdRequest.gender.rawValue : loggedInUser.gender ?? "",
                QueryParamsForAdRequest.city.rawValue : loggedInUser.city ?? "",
                QueryParamsForAdRequest.state.rawValue : loggedInUser.state ?? "",
                QueryParamsForAdRequest.country.rawValue : loggedInUser.country ?? "",
                QueryParamsForAdRequest.zipCode.rawValue : loggedInUser.zipCode ?? "",
                QueryParamsForAdRequest.adUnit.rawValue : adUnitId ?? "",
//                QueryParamsForAdRequest.br.rawValue : PatientSession().getBr(),
                QueryParamsForAdRequest.cdt.rawValue : "",
                QueryParamsForAdRequest.privacyConsent.rawValue: 1
            ]

            print("josnObject: ", josnObject)
            let body = josnObject
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config)
            var components = URLComponents()
            components.scheme = "https"
            components.host = getHost(type: DocereeMobileAds.shared().getEnvironment())
            components.path = getPath(methodName: Methods.GetImage)

            var urlRequest = URLRequest(url: (components.url)!)
            
            // set headers
            for header in requestHttpHeaders.allValues() {
                urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
            }
            
            urlRequest.httpMethod = HttpMethod.post.rawValue
            let jsonData: Data
            do {
                jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
                urlRequest.httpBody = jsonData
            } catch{
                return
            }
            let task = session.dataTask(with: urlRequest) {(data, response, error) in
                guard let data = data else { return }
//                data.printJSON()
                let urlResponse = response as! HTTPURLResponse
                if urlResponse.statusCode == 200 {
                    do {
                        let rs = try JSONDecoder().decode(AdResponseMain.self, from: data)
                        let adResponseData = rs.response[0]//try decoder.decode(AdResponse.self, from: data)
                        if adResponseData.errMessage != nil && adResponseData.errMessage!.count > 0 {
                            completion(Results(withData: nil, response: response as? HTTPURLResponse, error: DocereeAdRequestError.failedToCreateRequest), adResponseData.isAdRichMedia())
                            return
                        }
                        if !self.isPlatformUidPresent && adResponseData.newPlatformUid != nil {
                            // MARK check zone tag here later on for US based users' response
                            savePlatformuid(adResponseData.newPlatformUid!)
                        }
                        completion(Results(withData: data, response: response as? HTTPURLResponse, error: nil), adResponseData.isAdRichMedia())
                    } catch{
                        completion(Results(withData: nil, response: response as? HTTPURLResponse, error: DocereeAdRequestError.failedToCreateRequest), false)
                    }
                } else {
                    completion(Results(withData: nil, response: response as? HTTPURLResponse, error: DocereeAdRequestError.failedToCreateRequest), false)
                }
            }
            task.resume()
        } else {
            if #available(iOS 10.0, *){
                os_log("Unknown error", log: .default, type: .error)
            } else {
                print("Unknown error")
            }
        }
    }

    
    internal func sendAdImpression(impressionUrl: String) {
//        print("sendAdImpression: ", impressionUrl)
        let url: URL = URL(string: impressionUrl)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HttpMethod.get.rawValue
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        let task = session.dataTask(with: urlRequest){ (data, response, error) in
            guard data != nil else { return }
            data?.printJSON()
            let urlResponse = response as! HTTPURLResponse
            #if DEBUG
                print("impression sent. Http Status code is \(urlResponse.statusCode)")
            #endif
        }
        task.resume()
    }
    
    internal func sendAdViewability(viewLink: String) {
//        print("sendAdViewability: ", viewLink)
        let updatedUrl: String? = viewLink
        let url: URL = URL(string: updatedUrl!)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HttpMethod.get.rawValue
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        let task = session.dataTask(with: urlRequest){ (data, response, error) in
            guard data != nil else { return }
            let urlResponse = response as! HTTPURLResponse
            #if DEBUG
                print("viewability sent. Http Status code is \(urlResponse.statusCode)")
            #endif
        }
        task.resume()
    }
    
    internal func sendAdBlockRequest(_ advertiserCampID: String?, _ blockLevel: String?, _ platformUid: String?, _ publisherACSID: String?){
//        if ((advertiserCampID ?? "").isEmpty || (blockLevel ?? "").isEmpty || (platformUid ?? "").isEmpty || (publisherACSID ?? "").isEmpty) {
//            return
//        }
        
        let ua: String = UAString.init().UAString()
        // headers
        self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
        self.requestHttpHeaders.add(value: UAString.init().UAString(), forKey: HeaderEnum.header_user_agent.rawValue)
        
        // query params
        var httpBodyParameters = RestEntity()
        httpBodyParameters.add(value: advertiserCampID ?? "", forKey: AdBlockService.advertiserCampID.rawValue)
        httpBodyParameters.add(value: blockLevel ?? "", forKey: AdBlockService.blockLevel.rawValue)
        httpBodyParameters.add(value: platformUid ?? "", forKey: AdBlockService.platformUid.rawValue)
        httpBodyParameters.add(value: publisherACSID ?? "", forKey: AdBlockService.publisherACSID.rawValue)
        
        let body = httpBodyParameters.allValues()
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        var components = URLComponents()
        components.scheme = "https"
        components.host = getDocTrackerHost(type: DocereeMobileAds.shared().getEnvironment())
        components.path = getPath(methodName: Methods.AdBlock)
        let adBlockEndPoint: URL = components.url!
        var request: URLRequest = URLRequest(url: adBlockEndPoint)
        request.setValue(ua, forHTTPHeaderField: HeaderEnum.header_user_agent.rawValue)
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
            #if DEBUG
                print("Send Block:", urlResponse.statusCode)
            #endif
        }
        task.resume()
    }
    
    internal func sendDataCollection(screenPath: String?, editorialTags: [String]?, gps: String?, platformData: String?, event: [String : String]?) {
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
            #if DEBUG
                print("Data collection: ",urlResponse.statusCode)
            #endif
        }
        task.resume()

    }

}

extension Data
{
    func printJSON()
    {
        if let JSONString = String(data: self, encoding: String.Encoding.utf8)
        {
            print(JSONString)
        }
    }
}
