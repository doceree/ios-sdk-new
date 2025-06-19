//
//  DocereeAdView+Consent.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import UIKit

extension DocereeAdView {
    
    func setupConsentIcons() {
        let iconWidth = 20
        let iconHeight = 20
        
        // create and set cross icon
        if crossImageView == nil {
            if #available(iOS 13.0, *) {
                let lightConfiguration = UIImage.SymbolConfiguration(weight: .light)
                self.crossImageView = UIImageView(image: UIImage(systemName: "xmark.square", withConfiguration: lightConfiguration))
            } else {
                // Fallback on earlier versions
                self.crossImageView = UIImageView(image: UIImage(named: "xmark", in: nil, compatibleWith: nil))
            }
            crossImageView!.frame = CGRect(x: Int(adSize!.width) - iconWidth, y: iconHeight/10, width: iconWidth, height: iconHeight)
            crossImageView!.tintColor =  UIColor.init(hexString: "#6C40F7")
            crossImageView!.isUserInteractionEnabled = true
            let tapOnCrossButton = UITapGestureRecognizer(target: self, action: #selector(openAdConsentView))
            crossImageView!.addGestureRecognizer(tapOnCrossButton)
        }
        if !isRichMediaAd {
            self.adImageView.addSubview(crossImageView!)
        } else {
            self.adWebView.addSubview(crossImageView!)
        }

        // create and add info icon
        if infoImageView == nil {
            if #available(iOS 13.0, *) {
                let lightConfiguration = UIImage.SymbolConfiguration(weight: .light)
                self.infoImageView = UIImageView(image: UIImage(systemName: "info.circle", withConfiguration: lightConfiguration))
            } else {
                self.infoImageView = UIImageView(image: UIImage(named: "info", in: nil, compatibleWith: nil))
            }
            infoImageView!.frame = CGRect(x: Int(adSize!.width) - 2*iconWidth, y: iconHeight/10, width: iconWidth, height: iconHeight)
            infoImageView!.tintColor =  UIColor.init(hexString: "#6C40F7")
            infoImageView!.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(startLabelAnimation))
            infoImageView!.addGestureRecognizer(tap)
        }
        if !isRichMediaAd {
            self.adImageView.addSubview(infoImageView!)
        } else {
            self.adWebView.addSubview(infoImageView!)
        }
        
    }
    
    @objc func openAdConsentView(_ sender: UITapGestureRecognizer) {
        openAdConsent()
    }
    
    private func openAdConsent() {
        guard let adSize = self.adSize else { return }
        let consentUV = AdConsentUIView(with: adSize, frame: self.frame, rootVC: self.rootViewController, adView: self, isRichMedia: false)
        self.addSubview(consentUV!)
    }
    
    @objc func startLabelAnimation(_ sender: UITapGestureRecognizer) {
        
        let xCoords = CGFloat(0)
        let yCoords = CGFloat(self.infoImageView!.frame.origin.y)
        
        self.infoImageView!.layoutIfNeeded()
        let placeHolderView = UILabel()
        placeHolderView.text = "Ads by doceree"
        placeHolderView.font = placeHolderView.font.withSize(9)
        placeHolderView.textColor = ConsentConstants.brandPurple
        placeHolderView.frame = CGRect(x: xCoords, y: yCoords, width: 0, height: (self.infoImageView?.frame.height)!)
        self.infoImageView!.addSubview(placeHolderView)
        placeHolderView.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 1.0, animations: { [self] in
            placeHolderView.backgroundColor = UIColor(hexString: "#F2F2F2")
            placeHolderView.frame = CGRect(x: xCoords, y: yCoords, width: -placeHolderView.intrinsicContentSize.width, height: (self.infoImageView?.frame.height)!)
        }, completion: { (finished: Bool) in
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.openAdConsentView))
            self.infoImageView?.gestureRecognizers?.removeAll()
            self.infoImageView?.addGestureRecognizer(tap)
            placeHolderView.removeFromSuperview()
            self.openAdConsent()
        })
    }

}
