//
//  AdConsentFeedbackHandler.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 17/06/25.
//

import UIKit

extension AdConsentUIView {
    func loadAdConsentFeedback(_ adblockLevel: String) {
        guard let adSize = self.adViewSize else { return }
        resetConsentView()
        let consentView: UIView = UIView()
        consentView.frame = CGRect(x: 0.0, y: 0.0, width: adSize.width, height: adSize.height)
        consentView.backgroundColor = ConsentConstants.backgroundColor
        
        let label = UILabel()
        label.text = "Thank you for reporting this to us. \nYour feedback will help us improve. \nThis ad by doceree will now be closed."
        
        label.font = label.font.withSize(ConsentConstants.fontSize12)
        label.textColor = ConsentConstants.black
        label.frame = consentView.frame
        label.center.x = consentView.center.x
        label.center.y = consentView.center.y
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 3
        consentView.addSubview(label)
        consentView.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)

        self.docereeAdView?.sendViewTime(standard: "mrc", killSession: true)
        if (!self.isRichMedia) {
            self.docereeAdView!.addSubview(consentView)
        } else {
            for v in rootViewController!.view.subviews{
                v.removeFromSuperview()
            }
            consentView.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)
            self.rootViewController?.view.addSubview(consentView)
        }
        
        UIView.animate(withDuration: ConsentConstants.feedbackFadeDuration, delay: ConsentConstants.feedbackDelay, options: .curveEaseIn, animations: {
            consentView.alpha = 0
        }) { [self] _ in
            self.docereeAdView?.refresh()
            do {
                self.docereeAdView?.docereeAdRequest?.sendAdBlock(advertiserCampID: self.docereeAdView!.cbId, blockLevel: adblockLevel, platformUid: nil, publisherACSID: self.docereeAdView!.docereeAdUnitId)
            }
        }
    }
}
