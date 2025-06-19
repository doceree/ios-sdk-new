//
//  DocereeAdView+Loading.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import Foundation
import os.log

extension DocereeAdView {

    func fetchAd(_ size: String, _ uId: String) {
        Task {
            do {
                guard let request = docereeAdRequest else {
                    delegate?.docereeAdView(self, didFailToReceiveAdWithError: .invalidRequest)
                    return
                }
                
                let (results, isRichMediaAd) = try await request.requestAd(userId: uId, adUnitId: docereeAdUnitId, size: size)
                self.isRichMediaAd = isRichMediaAd
                
                guard let data = results.data else {
                    delegate?.docereeAdView(self, didFailToReceiveAdWithError: .invalidResponse)
                    return
                }
                
                let rs = try JSONDecoder().decode(AdResponseMain.self, from: data)
                self.adResponseData = rs.response.first
                
                if self.adResponseData?.status == -1 {
                    guard self.window != nil else { return }
                    self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: .adNotFound)
                    self.removeAllViews()
                } else {
                    self.createAdUI()
                }
                
                self.startTimer(adFound: true)
                
            } catch {
                os_log("Ad fetch failed: %@", log: .default, type: .error, error.localizedDescription)
                guard self.window != nil else { return }
                self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: error as? DocereeAdRequestError ?? .failedToCreateRequest)
                self.removeAllViews()
                self.startTimer(adFound: false)
            }
        }
    }

    func createAdUI() {
        if let tag = adResponseData?.passbackTag, !tag.isEmpty {
            createPassbackAd(tag: tag)
            return
        }
        
        self.cbId = adResponseData?.CBID?.split(separator: "_").first.map(String.init)
        self.docereeAdUnitId = adResponseData?.adUnit ?? ""
        self.ctaLink = adResponseData?.clickURL?.replacingOccurrences(of: "DOCEREE_CLICK_URL_UNESC", with: "")
        if var adRenderURL = adResponseData?.adRenderURL, !adRenderURL.isEmpty {
            adRenderURL = adRenderURL.replacingOccurrences(of: "{{EVENT_CLIENT_TIME}}", with: Date.currentTimeMillis())
            self.docereeAdRequest?.sendImpression(to: adRenderURL)
        }

        if !isRichMediaAd {
            createSimpleAd(imagePath: adResponseData?.imagePath)
        } else {
            if let script = adResponseData?.script {
                createRichMediaAd(script: script)
            }
        }
    }
    
}
