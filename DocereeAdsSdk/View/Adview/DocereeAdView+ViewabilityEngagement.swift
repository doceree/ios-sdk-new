//
//  DocereeAdView+ViewabilityEngagement.swift
//  DocereeAdsSdk
//

import UIKit

extension DocereeAdView {

    /// Engagement (eType=5) when scroll drops below 50% visible.
    func sendOffViewportEngagementIfNeeded() {
        guard hasLoadedAdForViewability(), !belowFiftyEngagementSent else { return }
        guard isAdViewingInProgress() else { return }
        if sendViewTime(standard: "mrc", adViewed: false) {
            belowFiftyEngagementSent = true
        }
    }

    /// Background: ≥50% on screen and viewing already started (`totalViewTime > 0`). Below 50% → scroll already sent engagement.
    func sendBackgroundEngagementIfNeeded() {
        guard hasLoadedAdForViewability(), isAdViewingInProgress() else { return }
        guard checkViewability(adView: self) >= 50 else { return }
        sendOffViewportEngagementIfNeeded()
    }

    /// Ad is “playing” (MRC view time counting); `totalViewTime == 0` means no active viewing session.
    func isAdViewingInProgress() -> Bool {
        totalViewTime > 0
    }

    func hasLoadedAdForViewability() -> Bool {
        guard let ad = adResponseData, ad.status != -1 else { return false }
        let isViewLinkEmpty = (ad.adViewedURL ?? "").isEmpty
        let isPassbackEmpty = (ad.passbackTag ?? "").isEmpty
        return !isViewLinkEmpty && isPassbackEmpty
    }
}
