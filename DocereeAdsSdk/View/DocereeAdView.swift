//
//  DocereeAdView.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 16/05/22.
//

import UIKit
import ImageIO
import SafariServices
import os.log
import WebKit
import OMSDK_Doceree
public final class DocereeAdView: UIView, UIApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    
    @IBOutlet public weak var rootViewController: UIViewController?
    
    //MARK: Properties
    public var docereeAdUnitId: String = String.init()
    public var delegate: DocereeAdViewDelegate?
    public var position: AdPosition = .custom
    
    var cbId: String?
    var docereeAdRequest: DocereeAdRequest?
    
    private var adSize: AdSize?
    private var ctaLink: String?
    private var crossImageView: UIImageView?
    private var infoImageView: UIImageView?
    private var isRichMediaAd = false
    private var customTimer: CustomTimer?
    private var viewportTimer: CustomTimer?
    private var adWebView: WKWebView!
    private var webViewInitialNavigation: WKNavigation?
    var sessionInteractor: OMIDSessionInteractor?
    
    static var didLeaveAd: Bool = false
    var adResponseData: AdResponseNew?
    private var totalViewTime = 0
    private var savedViewPercentage: Float = 0.0
    private var OneSecMrcSent = false
    private var viewportPercentage: Float = 90
    
    
    lazy var adImageView: UIImageView = {
        let adImageView = UIImageView()
        adImageView.translatesAutoresizingMaskIntoConstraints = false
        return adImageView
    }()
    
    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
 
    public convenience init?(with size: String?, and origin: CGPoint, adPosition: AdPosition?) {
        self.init()
        
        if size == nil {
            if #available(iOS 10.0, *) {
                os_log("Error: AdSize must be provided", log: .default, type: .error)
            } else {
                // Fallback on earlier versions
            }
            return
        }
        
        adSize = getAdSize(for: size)
        if adSize is Invalid {
            if #available(iOS 10.0, *) {
                os_log("Error: Please provide a valid size!", log: .default, type: .error)
            } else {
                // Fallback on earlier versions
            }
        }
        self.init(with: adSize, adPosition: adPosition!)
        if adSize!.width > UIScreen.main.bounds.width {
            self.adSize?.width = UIScreen.main.bounds.width
        }
        self.init(with: adSize, and: origin, adPosition: adPosition!)
    }

    private convenience init(with adSize: AdSize?, adPosition: AdPosition) {
        self.init(frame: CGRect(x: .zero, y: .zero, width: (adSize?.width)!, height: (adSize?.height)!))
        self.adSize = getAddSize(adSize: adSize!)
        self.position = adPosition
        addSubview(adImageView)
        setUpLayout()
    }
    
    private convenience init(with adSize: AdSize?, and origin: CGPoint, adPosition: AdPosition){
        self.init(frame: CGRect(x: origin.x, y: origin.y, width: (adSize?.width)!, height: (adSize?.height)!))
        self.adSize = adSize
        self.position = adPosition
        addSubview(adImageView)
        setUpLayout()
    }
    
    private func setUpLayout() {
        // uncomment for iOS versions 9, 10 and 11
        if self.position == .top || self.position == .bottom {
            self.translatesAutoresizingMaskIntoConstraints = false
        } else {
            self.translatesAutoresizingMaskIntoConstraints = true
        }
        clipsToBounds = true
        // add actions here
        let tap = UITapGestureRecognizer(target: self, action: #selector(DocereeAdView.onImageTouched(_:)))
        self.adImageView.addGestureRecognizer(tap)
        self.adImageView.isUserInteractionEnabled = true
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: (adSize?.width)!, height: (adSize?.height)!)
    }
    
    //MARK: Public methods
    public func load(_ docereeAdRequest: DocereeAdRequest) {
        // check for size existence
        if self.adSize == nil {
            return
        }

        // MARK : size restriction for iPhones & iPads
        if UIDevice.current.userInterfaceIdiom == .phone && (self.adSize?.getAdSizeName() == "LEADERBOARD" || self.adSize?.getAdSizeName() == "FULLBANNER") {
            if #available(iOS 10.0, *) {
                os_log("Invalid Request. Ad size will not fit on screen", log: .default, type: .error)
            } else {
                // Fallback on earlier versions
                print("Invalid Request. Ad size will not fit on screen")
            }
            return
        }
        
        totalViewTime = 0
        savedViewPercentage = 0
        self.OneSecMrcSent = false
        self.docereeAdRequest = docereeAdRequest
        let width: Int = Int((self.adSize?.getAdSize().width)!)
        let height: Int = Int((self.adSize?.getAdSize().height)!)
        let size = "\(width)x\(height)"
        
        let viewPercentage = checkViewability(adView: self)
        if viewPercentage >= viewportPercentage {
            var uId: String? = nil
            if let userId = adResponseData?.userId {
                uId = userId
            }
            docereeAdRequest.requestAd(uId, self.docereeAdUnitId, size) { (results, isRichMediaAd) in
                self.isRichMediaAd = isRichMediaAd
                if let data = results.data {
                    do {
                        let rs = try JSONDecoder().decode(AdResponseMain.self, from: data)
                        self.adResponseData = rs.response[0]
                        if (self.adResponseData?.status == -1) {
                            self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: DocereeAdRequestError.adNotFound)
                            self.removeAllViews()
                        } else {
                            self.createAdUI()
                        }
                    } catch {
                        self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: DocereeAdRequestError.failedToCreateRequest)
                        self.removeAllViews()
                    }
                    
                    DispatchQueue.main.async {
                        self.startTimer(adFound: true)
                    }
                    
                } else {
                    self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: DocereeAdRequestError.failedToCreateRequest)
                    self.removeAllViews()
                    
                    DispatchQueue.main.async {
                        self.startTimer(adFound: false)
                    }
                }
            }
        } else {
            self.viewportTimer(adFound: false)
        }
    }
    
    //MARK: Private methods
    
    private func startTimer(adFound: Bool) {

        customTimer?.stop()
        customTimer = CustomTimer { (seconds) in

            let isViewLinkNullOrEmpty: Bool = (self.adResponseData?.adViewedURL ?? "").isEmpty
            let isPassbackEmpty: Bool = (self.adResponseData?.passbackTag ?? "").isEmpty
            if adFound && (!isViewLinkNullOrEmpty) && isPassbackEmpty {
                let viewPercentage = checkViewability(adView: self)
//                print("final percentage: ", viewPercentage)
                
                // for standard: mcr
                if viewPercentage >= 50 {
                    self.totalViewTime += 1
                    self.savedViewPercentage = viewPercentage
                    if self.OneSecMrcSent == false {
                        self.sendViewTime(standard: "mrc")
                        self.OneSecMrcSent = true
                    }
                } else {
                    self.sendViewTime(standard: "mrc")
                }
                
                // for standard: custom
                if self.adResponseData?.standard() == "custom" {
                    if self.totalViewTime == self.adResponseData?.minViewTime && Int(viewPercentage) >= (self.adResponseData?.minViewPercentage)! {
                        self.sendViewTime(standard: "custom")
                    }
                }
            }
            if self.customTimer!.count % 30 == 0 {
                self.customTimer?.count = 0
                self.customTimer?.stop()
                self.sendViewTime(standard: "mrc")
                self.refresh()
            }
        }
        customTimer?.count = 0
        customTimer?.start()
    }
    
    private func viewportTimer(adFound: Bool) {

        viewportTimer?.stop()
        viewportTimer = CustomTimer { (seconds) in
            let viewPercentage = checkViewability(adView: self)
            if viewPercentage >= self.viewportPercentage {
                self.viewportTimer?.stop()
                self.refresh()
            }
        }
        viewportTimer?.count = 0
        viewportTimer?.start()
    }
    
    func sendViewTime(standard: String) {
        sessionInteractor?.stopSession()
        if totalViewTime > 0 && (savedViewPercentage > 50 || Int(savedViewPercentage) >= (self.adResponseData?.minViewPercentage)!) {
            #if DEBUG
                print("View Time: ", totalViewTime)
            #endif
            if var viewLink = adResponseData?.adViewedURL, !viewLink.isEmpty {
                viewLink = viewLink.replacingOccurrences(of: "{{EVENT_CLIENT_TIME}}", with: Date.currentTimeMillis())
                if standard == "mrc" {
                    if totalViewTime == 1 {
                        viewLink = viewLink.replacingOccurrences(of: "{{VIEWED_TIME}}", with: String(1))
                    } else {
                        viewLink = viewLink.replacingOccurrences(of: "{{VIEWED_TIME}}", with: String(totalViewTime))
                    }
                    viewLink = viewLink.replacingOccurrences(of: "{{VIEWED_PERCENTAGE}}", with: String(50))
                } else {
                    viewLink = viewLink.replacingOccurrences(of: "{{VIEWED_TIME}}", with: String((self.adResponseData?.minViewTime)!))
                    viewLink = viewLink.replacingOccurrences(of: "{{VIEWED_PERCENTAGE}}", with: String((self.adResponseData?.minViewPercentage)!))
                }
                viewLink = viewLink.replacingOccurrences(of: "_std", with: standard)
                self.docereeAdRequest?.sendAdViewability(viewLink: viewLink)
            }

            if standard == "mrc" && self.OneSecMrcSent == true {
                totalViewTime = 0
                savedViewPercentage = 0
            }
        }
    }
    
    private func createAdUI() {
        if let tag = adResponseData?.passbackTag, !tag.isEmpty {
            createPassbackAd(tag: tag)
        } else {
            self.cbId = adResponseData?.CBID?.components(separatedBy: "_")[0]
            self.docereeAdUnitId = adResponseData?.adUnit ?? ""
            self.ctaLink = adResponseData?.clickURL?.replacingOccurrences(of: "DOCEREE_CLICK_URL_UNESC", with: "")
            if var adRenderURL = adResponseData?.adRenderURL, !adRenderURL.isEmpty {
                adRenderURL = adRenderURL.replacingOccurrences(of: "{{EVENT_CLIENT_TIME}}", with: Date.currentTimeMillis())
                    self.docereeAdRequest?.sendAdImpression(impressionUrl: adRenderURL)
            }

            if !isRichMediaAd {
                createSimpleAd(imagePath: adResponseData?.imagePath)
            } else {
                if let script = adResponseData?.script {
                    createRichMediaAd(script: script)
                }
            }
        }
    }
    
    private func createSimpleAd(imagePath: String?) {
        if let urlString = imagePath, urlString.count > 0 {
            DispatchQueue.main.async {
                NotificationCenter.default.setObserver(observer: self, selector: #selector(self.appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
                NotificationCenter.default.setObserver(observer: self, selector: #selector(self.willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
                NotificationCenter.default.setObserver(observer: self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
                self.addSubview(self.adImageView)
                self.adImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
                self.adImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
                let imageUrl = URL(string: urlString)
                self.handleImageRendering(of: imageUrl)
                if self.delegate != nil {
                    self.delegate?.docereeAdViewDidReceiveAd(self)
                }
            }
        }
    }
    
    private func createRichMediaAd(script: String?) {
        // Handle Rich media ads here
        // Show mraid banner
        // get source url and download html body
        DispatchQueue.main.async {
            NotificationCenter.default.setObserver(observer: self, selector: #selector(self.appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.setObserver(observer: self, selector: #selector(self.willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.setObserver(observer: self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            self.initializeRichAds(frame: self.frame, body: self.createHTMLBody(script: script!))
            if self.delegate != nil {
                self.delegate?.docereeAdViewDidReceiveAd(self)
            }
        }
    }

    private func createPassbackAd(tag: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.setObserver(observer: self, selector: #selector(self.appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.setObserver(observer: self, selector: #selector(self.willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.setObserver(observer: self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
            self.initializeRichAds(frame: self.frame, body: self.createHTMLBody(script: tag))
            if self.delegate != nil {
                self.delegate?.docereeAdViewDidReceiveAd(self)
            }
        }
    }
    
    private func handleImageRendering(of imageUrl: URL?) {
        if imageUrl == nil || imageUrl?.absoluteString.count == 0 {
            return
        }
        if imageUrl?.pathExtension.lowercased() == "gif" {
            DispatchQueue.global().async {
                let image = UIImage.gifImageWithURL((imageUrl?.absoluteString)!)
                DispatchQueue.main.async {
                    self.adImageView.image = image
                }
            }
            setupConsentIcons()
        } else {
            ImageLoader.sharedInstance.downloadImage(from: imageUrl! as URL, completion: { (image) in
                self.adImageView.image = image
            })
            setupConsentIcons()
        }
    }

    private func setupConsentIcons() {
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
    
    @objc func startLabelAnimation(_ sender: UITapGestureRecognizer) {
        
        let xCoords = CGFloat(0)
        let yCoords = CGFloat(self.infoImageView!.frame.origin.y)
        
        self.infoImageView!.layoutIfNeeded()
        let placeHolderView = UILabel()
        placeHolderView.text = "Ads by doceree"
        placeHolderView.font = placeHolderView.font.withSize(9)
        placeHolderView.textColor = UIColor.init(hexString: "#6C40F7")
        placeHolderView.frame = CGRect(x: xCoords, y: yCoords, width: 0, height: (self.infoImageView?.frame.height)!)
        self.infoImageView!.addSubview(placeHolderView)
        placeHolderView.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 1.0, animations: { [self] in
            placeHolderView.backgroundColor = UIColor(hexString: "#F2F2F2")
            placeHolderView.frame = CGRect(x: xCoords, y: yCoords, width: -placeHolderView.intrinsicContentSize.width, height: (self.infoImageView?.frame.height)!)
        }, completion: { (finished: Bool) in
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.openAdConsentView))
            self.infoImageView?.addGestureRecognizer(tap)
            placeHolderView.removeFromSuperview()
            self.openAdConsent()
        })
    }
    
    @objc func openAdConsentView(_ sender: UITapGestureRecognizer) {
        openAdConsent()
    }
    
    private func openAdConsent() {
        let consentUV = AdConsentUIView(with: self.adSize!, frame: self.frame, rootVC: self.rootViewController, adView: self, isRichMedia: false)
//        if !isRichMediaAd {
//            self.adImageView.removeFromSuperview()
//        } else {
//            self.adWebView.removeFromSuperview()
//        }
        self.addSubview(consentUV!)
    }
    
    public override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    private func removeAllViews() {
        DispatchQueue.main.async {
            for v in self.subviews {
                v.removeFromSuperview()
            }
        }
    }
    
    //Mark: Action method
    @objc func onImageTouched(_ sender: UITapGestureRecognizer) {
        if let url = URL(string: "\(ctaLink ?? "")"), !url.absoluteString.isEmpty, UIApplication.shared.canOpenURL(url) {
            DocereeAdView.self.didLeaveAd = true
            viewportTimer?.stop()
            customTimer?.stop()
            self.sendViewTime(standard: "mrc")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            self.removeAllViews()
        }
    }
    
    @objc func appMovedToBackground() {
        viewportTimer?.stop()
        customTimer?.stop()
        self.sendViewTime(standard: "mrc")
        if  DocereeAdView.didLeaveAd && delegate != nil {
            delegate?.docereeAdViewWillLeaveApplication(self)
        }
    }
    
    @objc func willMoveToForeground() {
        if DocereeAdView.didLeaveAd && delegate != nil {
            delegate?.docereeAdViewWillDismissScreen(self)
        }
    }
    
    @objc func didBecomeActive() {
        if DocereeAdView.didLeaveAd && delegate != nil {
            delegate?.docereeAdViewDidDismissScreen(self)
            DocereeAdView.didLeaveAd = false
        }
        self.refresh()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        viewportTimer?.stop()
        customTimer?.stop()
        self.sendViewTime(standard: "mrc")
    }
    
    //will call on dismiss view
    public override func willMove(toWindow newWindow: UIWindow?) {
        if window != nil {
            NotificationCenter.default.removeObserver(self)
            viewportTimer?.stop()
            customTimer?.stop()
            self.sendViewTime(standard: "mrc")
        }
    }
    
    internal func refresh() {
        self.removeAllViews()
        if docereeAdRequest != nil && self.parentViewController != nil {
            load(self.docereeAdRequest!)
        }
    }
    
    
    // MARK: Rich Media Setup
    private func initializeRichAds(frame: CGRect?, body: String?) {
        initWebView(frame: frame!)
        let url = URL(fileURLWithPath: "https://adbserver.doceree.com/")
        webViewInitialNavigation = adWebView.loadHTMLString(body!, baseURL: url)
        setupConsentIcons()
    }
    
    // MARK: initialize webView
    private func initWebView(frame: CGRect) {
        let webConfiguration = WKWebViewConfiguration()
        // Fix Fullscreen mode for video and autoplay
//        webConfiguration.preferences.javaScriptEnabled = true
//        webConfiguration.mediaPlaybackRequiresUserAction = false
        webConfiguration.allowsInlineMediaPlayback = true
        adWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: adSize?.width ?? 320, height: adSize?.height ?? 100), configuration: webConfiguration)
        
//        adWebView = WKWebView()
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
        return injectOMID(intoHTML: htmlStr)
    }
    
    func injectOMID(intoHTML HTML: String) -> String {
        do {
            let creativeWithOMID = try OMIDDocereeScriptInjector.injectScriptContent(OMIDSessionInteractor.omidJSService, intoHTML:HTML)
            return creativeWithOMID
        } catch {
            fatalError("Unable to inject OMID JS into ad creative: \(error)")
        }
    }
}

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

// MARK: - WKScriptMessageHandler
extension DocereeAdView {
   
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if navigation === webViewInitialNavigation {
            print("WebView did finish loading creative")

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
