//
//  DocereeAdView+Timer.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import Foundation

extension DocereeAdView {
    
    func startTimer(adFound: Bool, resetViewabilityTickCounter: Bool = true) {
        customTimer?.stop()
        customTimer = CustomTimer { (seconds) in

            let isViewLinkNullOrEmpty: Bool = (self.adResponseData?.adViewedURL ?? "").isEmpty
            let isPassbackEmpty: Bool = (self.adResponseData?.passbackTag ?? "").isEmpty
            if adFound && (!isViewLinkNullOrEmpty) && isPassbackEmpty {
                let viewPercentage = checkViewability(adView: self)

                // for standard: mrc
                if viewPercentage >= 50 {
                    self.totalViewTime += 1
                    self.savedViewPercentage = viewPercentage
                    self.belowFiftyEngagementSent = false

                    if self.oneSecMrcSent == false {
                        self.sendViewTime(standard: "mrc", adViewed: true)
                        self.oneSecMrcSent = true
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
            self.viewabilityTickCounter += 1
            if self.viewabilityTickCounter % 30 == 0 {
                self.customTimer?.stop()
                self.sendViewTime(standard: "mrc", killSession: true, adViewed: false)
                self.safeRefresh()
            }
        }
        customTimer?.count = 0
        if resetViewabilityTickCounter {
            viewabilityTickCounter = 0
        }
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
    
    private func safeRefresh() {
        guard (self.delegate != nil) else { return }
        guard !isRefreshing else { return }
        isRefreshing = true
        refresh()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isRefreshing = false
        }
    }
}
