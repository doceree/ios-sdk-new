//
//  DocereeAdView+Lifecycle.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import UIKit
import os.log

private enum ViewabilityBackgroundSession {
    /// Wall-clock grace to resume the same 30s viewability cycle after background (scroll-back parity).
    static let reengagementGraceSeconds: TimeInterval = 30
}

extension DocereeAdView {
   
    @objc func appMovedToBackground() {
        os_log("App moved to background", log: .default, type: .debug)
        didEnterBackgroundFromViewability = true
        backgroundEnteredAt = Date()
        stopViewabilityTimers()
        sendBackgroundEngagementIfNeeded()
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

        guard didEnterBackgroundFromViewability else {
            return
        }
        didEnterBackgroundFromViewability = false

        if let enteredAt = backgroundEnteredAt {
            backgroundEnteredAt = nil
            let awaySeconds = Date().timeIntervalSince(enteredAt)
            if awaySeconds >= ViewabilityBackgroundSession.reengagementGraceSeconds {
                DocereeLog.debug(
                    "Foreground after \(ViewabilityBackgroundSession.reengagementGraceSeconds)s — ending ad session"
                )
                stopTimersAndSendMRC(killSession: true)
                refresh()
                return
            }
        }

        resumeViewabilityTimerOnForeground()
    }
    
    //will call on dismiss view
    public override func willMove(toWindow newWindow: UIWindow?) {
        if window != nil {
            self.delegate = nil
            NotificationCenter.default.removeObserver(self)
            stopTimersAndSendMRC(killSession: true)
        }
    }

    /// RN `startTimer` on app active — same creative, do not reset session tick counter.
    func resumeViewabilityTimerOnForeground() {
        DocereeLog.debug("Resuming viewability timer on foreground")
        startTimer(adFound: hasLoadedAdForViewability(), resetViewabilityTickCounter: false)
    }

    func stopViewabilityTimers() {
        viewportTimer?.stop()
        customTimer?.stop()
    }

    func stopTimersAndSendMRC(killSession: Bool = false) {
        stopViewabilityTimers()
        sendViewTime(standard: "mrc", killSession: killSession, adViewed: false)
    }

}
