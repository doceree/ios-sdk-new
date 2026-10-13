//
//  DocereeAdView+Lifecycle.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import UIKit
import os.log

extension DocereeAdView {
   
    @objc func appMovedToBackground() {
        os_log("App moved to background", log: .default, type: .debug)
        didEnterBackgroundFromViewability = true
        viewportTimer?.stop()
        customTimer?.stop()
        sendBackgroundEngagementIfNeeded()
        if isViewabilityCycleComplete() {
            didEnterBackgroundFromViewability = false
            onViewabilityCycleComplete(reason: "background-after-cycle")
            return
        }
        if DocereeAdView.didLeaveAd {
            delegate?.docereeAdViewWillLeaveApplication(self)
        }
    }
    
    @objc func willMoveToForeground() {
        if DocereeAdView.didLeaveAd {
            delegate?.docereeAdViewWillDismissScreen(self)
        }
    }
    
    @objc func didBecomeActive() {
        if DocereeAdView.didLeaveAd {
            delegate?.docereeAdViewDidDismissScreen(self)
            DocereeAdView.didLeaveAd = false
        }
        DocereeBeaconQueue.flushQueue()
        if isWaitingForNetworkRecovery() {
            DocereeLog.debug("Skipping viewability resume — waiting for network recovery poll")
            return
        }

        if isViewabilityCycleComplete() {
            didEnterBackgroundFromViewability = false
            onViewabilityCycleComplete(reason: "foreground-after-cycle")
            return
        }

        if refreshPendingAfterCycle {
            didEnterBackgroundFromViewability = false
            tryPerformCycleRefresh(reason: "foreground-pending")
            return
        }

        guard didEnterBackgroundFromViewability else {
            return
        }
        didEnterBackgroundFromViewability = false

        startTimer(adFound: hasLoadedAdForViewability(), resetViewabilityCycle: false)
    }
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        if window != nil {
            self.delegate = nil
            NotificationCenter.default.removeObserver(self)
            stopPendingRefreshPoll()
            stopTimersAndSendMRC(killSession: true)
        }
    }

    func stopViewabilityTimers() {
        stopPendingRefreshPoll()
        viewportTimer?.stop()
        customTimer?.stop()
    }

    func stopTimersAndSendMRC(killSession: Bool = false) {
        stopViewabilityTimers()
        refreshPendingAfterCycle = false
        sendViewTime(standard: "mrc", killSession: killSession, adViewed: false)
        ActiveAdRecoveryStore.clear()
    }

}
