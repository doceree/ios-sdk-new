//
//  DocereeAdView+WebViewDelegate.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import Foundation
@preconcurrency import WebKit

extension DocereeAdView {
    /* Handle HTTP requests from the webview */
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated  {
            if let url = navigationAction.request.url,
               let host = url.host, !host.hasPrefix("www.google.com"),
               UIApplication.shared.canOpenURL(url) {
                DocereeAdView.didLeaveAd = true
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    // Fallback on earlier versions
                    UIApplication.shared.openURL(url)
                }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil || navigationAction.targetFrame?.isMainFrame == false {
            if let url = navigationAction.request.url {
                if UIApplication.shared.canOpenURL(url) {
                    DocereeAdView.didLeaveAd = true
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
        return nil
    }
    
}

// MARK: - WKScriptMessageHandler
extension DocereeAdView {
  
   public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
       if navigation === webViewInitialNavigation {
        #if DEBUG
            print("WebView did finish loading creative")
        #endif

           // This is an equivalent of listening to DOMContentLoaded event in JS
           // OMID JS service is not guaranteed to handle any events prior to this point and you
           // should avoid executing native impression event (registered in presentAd()) until DOM
           // is loaded completely. If you're pre-rendering webviews, then waiting for window.onload
           // event is also an option)

           // OMID JS service is now fully operational and it's safe to display the webview and
           // register impression
           sessionInteractor = OMIDSessionInteractor(adUnit: .HTMLDisplay, webCreative: webView)
//            sessionInteractor?.addCloseButtonObstruction(closeButton)
           
           sessionInteractor?.startSession()
           //Don't need to fire the loaded event from native code as this should happen from the webview
//            presentAd()
       }
   }
}
