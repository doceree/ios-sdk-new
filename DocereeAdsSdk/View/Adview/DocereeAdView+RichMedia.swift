//
//  DocereeAdView+RichMedia.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import Foundation
import WebKit
import OMSDK_Doceree
import os.log

extension DocereeAdView {
    
    func initializeRichAds(frame: CGRect?, body: String?) {
        guard let frame = frame, let body = body else {
            os_log("Rich ad init failed: frame or body is nil", log: .default, type: .error)
            return
        }
        initWebView(frame: frame)
        
        let url = URL(fileURLWithPath: "https://adbserver.doceree.com/")
        webViewInitialNavigation = adWebView.loadHTMLString(body, baseURL: url)
        setupConsentIcons()
    }
    
    // MARK: initialize webView
    private func initWebView(frame: CGRect) {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        adWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: adSize?.width ?? 320, height: adSize?.height ?? 100), configuration: webConfiguration)

        adWebView.configuration.allowsInlineMediaPlayback = true
        adWebView.navigationDelegate = self
        adWebView.uiDelegate = self
        adWebView.translatesAutoresizingMaskIntoConstraints = false
        adWebView.scrollView.isScrollEnabled = false
        adWebView.isOpaque = true
        adWebView.isUserInteractionEnabled = true
        self.addSubview(adWebView)
        setInitialConstraints()
    }
    
    // webview should always be the same size as the main view
    private func setInitialConstraints() {
        NSLayoutConstraint.activate([
            adWebView.widthAnchor.constraint(equalTo: self.widthAnchor),
            adWebView.heightAnchor.constraint(equalTo: self.heightAnchor),
            adWebView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            adWebView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    func createHTMLBody(script: String) -> String {
        let htmlStr = "<html><head><style>html,body{padding:0;margin:0;}</style><meta name='viewport' content='width=device-width,initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0'></head><body>\(script)</body></html>"
        return injectOMID(intoHTML: htmlStr)
    }
    
    func injectOMID(intoHTML HTML: String) -> String {
        do {
            let creativeWithOMID = try OMIDDocereeScriptInjector.injectScriptContent(OMIDSessionInteractor.omidJSService, intoHTML:HTML)
            return creativeWithOMID
        } catch {
            os_log("OMID injection failed: %@", log: .default, type: .error, error.localizedDescription)
            return HTML
        }
    }
}
