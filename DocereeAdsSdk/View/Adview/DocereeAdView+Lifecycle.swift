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
        stopTimersAndSendMRC()
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
        self.refresh()
    }
    
    //will call on dismiss view
    public override func willMove(toWindow newWindow: UIWindow?) {
        if window != nil {
            NotificationCenter.default.removeObserver(self)
            stopTimersAndSendMRC(killSession: true)
        }
    }
    
    private func stopTimersAndSendMRC(killSession: Bool = false) {
        viewportTimer?.stop()
        customTimer?.stop()
        sendViewTime(standard: "mrc", killSession: killSession)
    }

}
