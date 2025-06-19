//
//  DocereeAdView+AdUI.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import UIKit

extension DocereeAdView {
    
    func createSimpleAd(imagePath: String?) {
        if let urlString = imagePath, !urlString.isEmpty {
            DispatchQueue.main.async {
                self.adImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
                self.adImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
                let imageUrl = URL(string: urlString)
                self.handleImageRendering(of: imageUrl)
                self.prepareAdRendering()
            }
        }
    }
    
    func createRichMediaAd(script: String?) {
        // Handle Rich media ads here
        // Show mraid banner
        // get source url and download html body
        DispatchQueue.main.async {
            guard let script = script else { return }
            self.initializeRichAds(frame: self.frame, body: self.createHTMLBody(script: script))
            self.prepareAdRendering()
        }
    }

    func createPassbackAd(tag: String) {
        DispatchQueue.main.async {
            self.initializeRichAds(frame: self.frame, body: self.createHTMLBody(script: tag))
            self.prepareAdRendering()
        }
    }
    
    private func prepareAdRendering() {
        registerLifecycleObservers()
        delegate?.docereeAdViewDidReceiveAd(self)
    }

    private func registerLifecycleObservers() {
        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
}
