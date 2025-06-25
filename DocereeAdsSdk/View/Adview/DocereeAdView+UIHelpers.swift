//
//  DocereeAdView+UIHelpers.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import UIKit

extension DocereeAdView {
    
    func removeAllViews() {
        DispatchQueue.main.async {
            self.subviews.forEach { $0.removeFromSuperview() }
        }
    }
    
    func handleImageRendering(of imageUrl: URL?) {
        if imageUrl == nil || imageUrl?.absoluteString.count == 0 {
            return
        }
        if imageUrl?.pathExtension.lowercased() == "gif" {
            DispatchQueue.global().async {
                if let urlString = imageUrl?.absoluteString,
                   let image = UIImage.gifImageWithURL(urlString) {
                    DispatchQueue.main.async {
                        self.adImageView.image = image
                    }
                }
            }
        } else {
            if let imageUrl = imageUrl {
                ImageLoader.sharedInstance.downloadImage(from: imageUrl, completion: { image in
                    self.adImageView.image = image
                })
            }
        }
        setupConsentIcons()
    }

    func sendViewTime(standard: String, killSession: Bool = false) {
        if let session = sessionInteractor, killSession {
            session.stopSession()
        }
        if totalViewTime > 0 && (savedViewPercentage > 50 || Int(savedViewPercentage) >= (self.adResponseData?.minViewPercentage)!) {
            #if DEBUG
                print("View Time: ", totalViewTime)
            #endif
            if var viewLink = adResponseData?.adViewedURL, !viewLink.isEmpty {
                let time = standard == "mrc" ? totalViewTime : (self.adResponseData?.minViewTime ?? 0)
                let percentage = standard == "mrc" ? 50 : (self.adResponseData?.minViewPercentage ?? 0)
                viewLink = populateTokens(in: viewLink, time: time, percent: percentage, standard: standard)
                self.docereeAdRequest?.sendViewability(to: viewLink)
            }

            if standard == "mrc" && self.oneSecMrcSent == true {
                totalViewTime = 0
                savedViewPercentage = 0
            }
        }
    }
    
    func populateTokens(in url: String, time: Int, percent: Int, standard: String) -> String {
        return url
            .replacingOccurrences(of: "{{EVENT_CLIENT_TIME}}", with: Date.currentTimeMillis())
            .replacingOccurrences(of: "{{VIEWED_TIME}}", with: String(time))
            .replacingOccurrences(of: "{{VIEWED_PERCENTAGE}}", with: String(percent))
            .replacingOccurrences(of: "_std", with: standard)
    }
}
