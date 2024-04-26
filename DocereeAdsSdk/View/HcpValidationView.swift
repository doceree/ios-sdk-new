//
//  HcpValidationView.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 01/04/24.
//

import UIKit
import WebKit

public class HcpValidationView: UIView, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler  {

    private var adWebView: WKWebView!
//    var hcpValidationRequest: HcpValidationRequest?
    
    var containerView: UIView!
    public var delegate: HcpValidationViewDelegate?
    
    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: CGRectMake(0, 0, UIScreen.main.bounds.width, UIScreen.main.bounds.height))
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func onClickButton(buttonId: String) {
        print("Button clicked with ID: \(buttonId)")
        var duration: TimeInterval
        var action: PopupAction
        switch(buttonId) {
        case "cookie-accept-btn":
            duration = ExpirationDuration.year1
            action = .accept
        case "cookie-decline-btn":
            duration = ExpirationDuration.days15
            action = .reject
        default:
            duration = ExpirationDuration.hours6
            action = .close
        }
        
        saveTimeInterval(duration: duration)
        self.delegate?.hcpPopupAction(action)
    }
    
    func saveTimeInterval(duration: TimeInterval) {
        let manager = UserDefaultsManager.shared

        manager.setUserDefaults(duration)

        // Retrieve user defaults
        if let userData = manager.getUserDefaults() {
            print("User defaults exist for \(duration):", userData)
        } else {
            print("User defaults expired or not set.")
        }
        self.removeFromSuperview()
    }
    
    func getInterval() -> Bool {
        let manager = UserDefaultsManager.shared
        manager.expirationDuration = ExpirationDuration.minutes10
        // Retrieve user defaults
        if let userData = manager.getUserDefaults() {
            print("User defaults exist for :", userData)
            return false
        } else {
            print("User defaults expired or not set.")
            return true
        }
    }

    public func loadData(hcpValidationRequest: HcpValidationRequest) {

        if (!getInterval()) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // code to remove your view
                self.removeFromSuperview()
            }
            return
        }
        
        hcpValidationRequest.getHcpSelfValidation("uId") { (results) in
            if let result = results.data {
                do {
                    let response = try JSONDecoder().decode(HcpValidation.self, from: result)
                    let data: HcpValidationData = response.data
                    DispatchQueue.main.async {
                        if let script = data.script {
                            self.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
                            print("body: ", self.createHTMLBody(script: (script.fromBase64())!))
                            self.initializeRichAds(body: self.createHTMLBody(script: (script.fromBase64())!))
                            self.delegate?.hcpValidationViewSuccess(self)
                        }
                        else {
                            self.removeFromSuperview()
                            print("No script found")
                        }
                    }
                } catch {
//                    self.delegate?.hcpValidationView(self, didFailToReceiveHcpWithError: HcpRequestError.parsingError)
                    self.removeFromSuperview()
                }
                
            } else {
                self.removeFromSuperview()
            }
        }
    }
    
    // MARK: Rich Media Setup
    private func initializeRichAds(body: String?) {
        initWebView(frame: CGRectMake(0, 0, UIScreen.main.bounds.width, UIScreen.main.bounds.height))
        let url = URL(fileURLWithPath: "https://adbserver.doceree.com/")
        adWebView.loadHTMLString(body!, baseURL: url)
    }
    
    // MARK: initialize webView
    private func initWebView(frame: CGRect) {
        
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width - 40, height: 0))
        containerView.layer.cornerRadius = 10
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.lightGray.cgColor
        containerView.layer.masksToBounds = true
        containerView.backgroundColor = .white
        self.addSubview(containerView)
        
        
        let webConfiguration = WKWebViewConfiguration()
                let userContentController = WKUserContentController()
                userContentController.add(self, name: "buttonClicked")
                webConfiguration.userContentController = userContentController
        
        // Fix Fullscreen mode for video and autoplay
//        webConfiguration.preferences.javaScriptEnabled = true
//        webConfiguration.mediaPlaybackRequiresUserAction = false
        webConfiguration.allowsInlineMediaPlayback = true
        adWebView = WKWebView(frame: CGRect(x: containerView.bounds.origin.x, y: containerView.bounds.origin.y, width: containerView.bounds.width, height: 0), configuration: webConfiguration)
        adWebView.configuration.allowsInlineMediaPlayback = true
        adWebView.navigationDelegate = self
        adWebView.uiDelegate = self
        adWebView.translatesAutoresizingMaskIntoConstraints = false
        adWebView.scrollView.isScrollEnabled = false
        adWebView.isOpaque = true
        adWebView.isUserInteractionEnabled = true
        containerView.addSubview(adWebView)
        
    }
    
    // webview should always be the same size as the main view
    private func setInitialConstraints() {
        let webViewSizeConstraints = [
            NSLayoutConstraint(item: self as Any, attribute: .width, relatedBy: .equal, toItem: adWebView, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self as Any, attribute: .height, relatedBy: .equal, toItem: adWebView, attribute: .height, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self as Any, attribute: .centerX, relatedBy: .equal, toItem: adWebView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self as Any, attribute: .centerY, relatedBy: .equal, toItem: adWebView, attribute: .centerY, multiplier: 1.0, constant: 0),
        ]
        self.addConstraints(webViewSizeConstraints)
    }

    private func createHTMLBody(script: String) -> String {
        let htmlStr = "<html><head><style>html,body{padding:0;margin:0;}</style><meta name='viewport' content='width=device-width,initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0'></head><body>\(script)</body></html>"
        return htmlStr
    }
    
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let jsCode = """
            var buttons = document.querySelectorAll('.doc-action-btn');
            buttons.forEach(function(button) {
                button.addEventListener('click', function() {
                    window.webkit.messageHandlers.buttonClicked.postMessage(button.id);
                });
            });
        """
        adWebView.evaluateJavaScript(jsCode, completionHandler: nil)
        
            // Resize the web view based on its content size
            webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
                if complete != nil {
                    webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
                        if let height = height as? CGFloat {
                            var frame = webView.frame
                            frame.size.height = height
                            
                            // Update the height of the container view to match the content size
                            self.containerView.frame.size.height = height + 20
                            self.containerView.center = self.center
                            
//                            self.adWebView.frame.origin.y = 25
                            self.adWebView.frame.size.height = height
                        }
                    })
                }
            })
        }
    
    // Handle messages from JavaScript
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "buttonClicked" {
            if let buttonId = message.body as? String {
                // Handle button click here
                onClickButton(buttonId: buttonId)
            }
        }
    }
    
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
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url)
                    } else {
                        // Fallback on earlier versions
                        UIApplication.shared.openURL(url)
                    }
                }
            }
        }
        return nil
    }
    
}
