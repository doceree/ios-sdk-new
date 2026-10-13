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

    @discardableResult
    func sendViewTime(standard: String, killSession: Bool = false, adViewed: Bool = false) -> Bool {
        if let session = sessionInteractor, killSession {
            session.stopSession()
        }
        let minViewPercentRequired = adResponseData?.minViewPercentage ?? 0
        let meetsViewThreshold = savedViewPercentage > 50 || Int(savedViewPercentage) >= minViewPercentRequired
        guard totalViewTime > 0 && meetsViewThreshold else { return false }

        DocereeLog.debug("View Time: \(totalViewTime)")
        guard var viewLink = adResponseData?.adViewedURL, !viewLink.isEmpty else { return false }

        let time = standard == "mrc" ? totalViewTime : (self.adResponseData?.minViewTime ?? 0)
        let percentage = standard == "mrc" ? 50 : (self.adResponseData?.minViewPercentage ?? 0)
        viewLink = AdViewedURLPopulator.populate(
            url: viewLink,
            viewedTime: time,
            viewedPercentage: percentage,
            standard: standard,
            adViewed: adViewed
        )
        let eType = AdViewedURLPopulator.eventType(from: adViewed)
        DocereeLog.debug(
            "sendViewTime standard=\(standard) adViewed=\(adViewed) eType=\(eType)"
        )
        self.docereeAdRequest?.sendViewability(to: viewLink)

        if standard == "mrc" && self.oneSecMrcSent == true {
            totalViewTime = 0
            savedViewPercentage = 0
            if !adViewed {
                ActiveAdRecoveryStore.clear()
            }
        }
        return true
    }
    
}
