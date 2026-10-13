//
//  DocereeAdView+Timer.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import UIKit

extension DocereeAdView {
    
    func startTimer(adFound: Bool, resetViewabilityCycle: Bool = true) {
        customTimer?.stop()
        beginViewabilityCycleIfNeeded(reset: resetViewabilityCycle)

        customTimer = CustomTimer { (seconds) in
            guard UIApplication.shared.applicationState == .active else { return }

            let isViewLinkNullOrEmpty: Bool = (self.adResponseData?.adViewedURL ?? "").isEmpty
            let isPassbackEmpty: Bool = (self.adResponseData?.passbackTag ?? "").isEmpty
            if adFound && (!isViewLinkNullOrEmpty) && isPassbackEmpty {
                let viewPercentage = checkViewability(adView: self)

                if viewPercentage >= 50 {
                    self.totalViewTime += 1
                    self.savedViewPercentage = viewPercentage
                    self.belowFiftyEngagementSent = false
                    self.persistActiveAdSnapshotIfNeeded()

                    if self.oneSecMrcSent == false {
                        self.sendViewTime(standard: "mrc", adViewed: true)
                        self.oneSecMrcSent = true
                        self.persistActiveAdSnapshotIfNeeded()
                    }
                } else {
                    self.sendOffViewportEngagementIfNeeded()
                }

                if !self.customEngagementSent,
                   self.adResponseData?.standard() == "custom",
                   let minTime = self.adResponseData?.minViewTime,
                   let minPercent = self.adResponseData?.minViewPercentage,
                   self.totalViewTime == minTime,
                   Int(viewPercentage) >= minPercent {
                    self.sendViewTime(standard: "custom", adViewed: false)
                    self.customEngagementSent = true
                }
            }

            if self.isViewabilityCycleComplete() {
                self.onViewabilityCycleComplete(reason: "tick")
            }
        }
        customTimer?.count = 0
        customTimer?.start()
    }
    
    func viewportTimer(adFound: Bool) {
        viewportTimer?.stop()
        viewportTimer = CustomTimer { (seconds) in
            let viewPercentage = checkViewability(adView: self)
            if viewPercentage >= self.viewportPercentage {
                self.viewportTimer?.stop()
                self.safeRefresh()
            }
        }
        viewportTimer?.count = 0
        viewportTimer?.start()
    }
}
