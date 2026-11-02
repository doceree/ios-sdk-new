//
//  DocereeAdView+ActiveAdRecovery.swift
//  DocereeAdsSdk
//

import UIKit

extension DocereeAdView {

    /// Persist viewing state so kill → next launch can send deferred engagement.
    func persistActiveAdSnapshotIfNeeded() {
        guard hasLoadedAdForViewability(), totalViewTime > 0,
              let url = adResponseData?.adViewedURL, !url.isEmpty else { return }
        ActiveAdRecoveryStore.mark(
            adViewedURL: url,
            totalViewTime: totalViewTime,
            savedViewPercentage: Double(DocereeDecimalPrecision.roundToTwoDecimals(savedViewPercentage)),
            oneSecMrcSent: oneSecMrcSent
        )
    }
}
