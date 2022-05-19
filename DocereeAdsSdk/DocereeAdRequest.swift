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
    
    private var size: String?
    private var adUnitId: String?
    private let addsWebRepo: AdWebRepoProtocol = AdWebRepo()
    private var disposables = Set<AnyCancellable>()
    
    // todo: create a queue of requests and inititate request
    public init() {
    }
    
    // MARK: Properties
    private var isPlatformUidPresent: Bool = false
    
    // MARK: Public methods
    internal func requestAd(_ adUnitId: String!, _ size: String!, completion: @escaping(_ results: Results,
                                                                                        _ isRichMediaAd: Bool) -> Void){
        self.adUnitId = adUnitId
        self.size = size
        setUpImage(){ (results, isRichMediaAd) in
            completion(results, isRichMediaAd)
        }
    }
    
    internal func sendImpression(impressionUrl: String){
        addsWebRepo.sendAdImpression(request: impressionUrl)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    break
                }
            } receiveValue: { (data, response) in
                print("impressionUrl: ", response, data)
            }
            .store(in: &disposables)
    }

    internal func setUpImage(completion: @escaping(_ results: Results, _ isRichmedia: Bool) -> Void){
        
        guard let appKey = Bundle.main.object(forInfoDictionaryKey: "DocereeAdsIdentifier") as? String else {
            if #available(iOS 10.0, *) {
                os_log("Error: Missing DocereeIdentifier key!", log: .default, type: .error)
            } else {
                // Fallback on earlier versions
                print("Error: Missing DocereeIdentifier key!")
            }
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

        if advertisementId != nil {
            var bse64Str = ""
            guard let userProfile = DocereeMobileAds.getProfile() else {
                return
            }
 
             if let platformuid = NSKeyedUnarchiver.unarchiveObject(withFile: PlatformArchivingUrl.path) as? String {
                 var data: Dictionary<String, String?> = Dictionary()
                 if userProfile.npi != nil {
                     data = ["platformUid": platformuid]
                 } else {
                     data = ["platformUid": platformuid,
                             "city": userProfile.city,
                             "specialization": userProfile.specialization]
                 }


                 let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
                 bse64Str = (String(data: jsonData!, encoding: .utf8)?.toBase64()) ?? "" // encode to base64
                 self.isPlatformUidPresent = true
             } else {
                 let jsonEncoder = JSONEncoder()
                 jsonEncoder.outputFormatting = .prettyPrinted
                 let jsonData = try? jsonEncoder.encode(userProfile)
                 let json = String(data: jsonData!, encoding: .utf8)!
                 let data: Data = json.data(using: .utf8)!
                 bse64Str = String(data: data, encoding: .utf8)!.replacingOccurrences(of: "\n", with: "").toBase64() ?? ""
                 self.isPlatformUidPresent = false
             }

            let request = AdRequest(id: adUnitId ?? "", size: size ?? "", platformType: "mobileApp", appKey: appKey, loggedInUser: bse64Str)
            addsWebRepo.getAdImage(request: request)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
//                        fatalError(error.localizedDescription)
//                        completion(Results(withData: nil, response: nil, error: DocereeAdRequestError.failedToCreateRequest), false)
                    }
                } receiveValue: { (data, response) in
                    do{
                        let adResponseData: AdResponse = try JSONDecoder().decode(AdResponse.self, from: data)
                                            print("getImage response \(adResponseData)")
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
                }
                .store(in: &disposables)
        } else {
            if #available(iOS 10.0, *){
                os_log("Unknown error", log: .default, type: .error)
            } else {
                print("Unknown error")
            }
        }
    }
}

