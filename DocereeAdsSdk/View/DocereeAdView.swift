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
    private var adWebView: WKWebView!
    
    static var didLeaveAd: Bool = false
    
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
                print("adSize:", adSize as Any)
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
        
        self.docereeAdRequest = docereeAdRequest
        let width: Int = Int((self.adSize?.getAdSize().width)!)
        let height: Int = Int((self.adSize?.getAdSize().height)!)
        let size = "\(width)x\(height)"
        
        docereeAdRequest.requestAd(self.docereeAdUnitId, size) { (results, isRichMediaAd) in
            if let data = results.data {
                self.isRichMediaAd = isRichMediaAd
                self.createAdUI(data: data, isRichMediaAd: isRichMediaAd)
            } else {
                self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: DocereeAdRequestError.failedToCreateRequest)
                self.removeAllViews()
            }
        }
        startTimer()
    }
    
    //MARK: Private methods
    
    private func startTimer() {
        customTimer?.stop()
        customTimer = CustomTimer { (seconds) in
            if self.customTimer!.count % 30 == 0 {
                self.customTimer?.count = 0
                self.refresh()
            }
        }
        customTimer?.count = 0
        customTimer?.start()
    }
    
    private func createAdUI(data: Data, isRichMediaAd: Bool) {
        let decoder = JSONDecoder()
        do {
            let adResponseData: AdResponse = try decoder.decode(AdResponse.self, from: data)
            if (adResponseData.sourceURL ?? "").isEmpty {
                self.removeAllViews()
                return
            }
            self.cbId = adResponseData.CBID?.components(separatedBy: "_")[0]
            self.docereeAdUnitId = adResponseData.DIVID!
            self.ctaLink = adResponseData.ctaLink
            let isImpressionLinkNullOrEmpty: Bool = (adResponseData.impressionLink ?? "").isEmpty
            if (!isImpressionLinkNullOrEmpty) {
                self.docereeAdRequest?.sendAdImpression(impressionUrl: adResponseData.impressionLink!)
            }
            if !isRichMediaAd {
                createSimpleAd(sourceURL: adResponseData.sourceURL)
            } else {
                createRichMediaAd(sourceURL: adResponseData.sourceURL)
            }
        } catch {
            self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: DocereeAdRequestError.failedToCreateRequest)
            self.removeAllViews()
        }
    }
    
    private func createSimpleAd(sourceURL: String?) {
        if let urlString = sourceURL, urlString.count > 0 {
            DispatchQueue.main.async {
                NotificationCenter.default.setObserver(observer: self, selector: #selector(self.appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
                NotificationCenter.default.setObserver(observer: self, selector: #selector(self.willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
                NotificationCenter.default.setObserver(observer: self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
                self.addSubview(self.adImageView)
                self.adImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
                self.adImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
                let imageUrl = NSURL(string: urlString)
                self.handleImageRendering(of: imageUrl)
                if self.delegate != nil {
                    self.delegate?.docereeAdViewDidReceiveAd(self)
                }
            }
        }
    }
    
    private func createRichMediaAd(sourceURL: String?) {
        // Handle Rich media ads here
        // Show mraid banner
        // get source url and download html body
        if let urlString = sourceURL, urlString.count > 0 {
            if let url = URL(string: urlString) {
                do {
                    let htmlContent = try String(contentsOf: url)
                    var refinedHtmlContent = htmlContent.withReplacedCharacter("<head>", by: "<head><style>html,body{padding:0;margin:0;}</style><base href=" + (urlString.components(separatedBy: "unzip")[0]) + "unzip/" + "target=\"_blank\">")
                    if (self.ctaLink != nil && self.ctaLink!.count > 0) {
                        refinedHtmlContent = refinedHtmlContent.replacingOccurrences(of: "[TRACKING_LINK]", with: self.ctaLink!)
                    }
                    let body: String = refinedHtmlContent
                    if (body.count == 0) {
                        return
                    }
                    DispatchQueue.main.async {
                        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
                        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
                        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
                        self.initializeRichAds(frame: self.frame, body: body)
                        if self.delegate != nil {
                            self.delegate?.docereeAdViewDidReceiveAd(self)
                        }
                    }
                } catch {
                    self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: DocereeAdRequestError.failedToCreateRequest)
                    self.removeAllViews()
                }
            } else {
                self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: DocereeAdRequestError.failedToCreateRequest)
                self.removeAllViews()
            }
        }
    }

    private func handleImageRendering(of imageUrl: NSURL?) {
        if imageUrl == nil || imageUrl?.absoluteString?.count == 0 {
            return
        }
        if NSData(contentsOf: imageUrl! as URL)?.imageFormat == ImageFormat.GIF {
            let url = imageUrl
            let image = UIImage.gifImageWithURL((url?.absoluteString)!)
            self.adImageView.image = image
            setupConsentIcons()
        } else {
            guard let imageSource = CGImageSourceCreateWithURL(imageUrl!, nil) else {
                return
            }
            let image = UIImage(cgImage: CGImageSourceCreateImageAtIndex(imageSource, 0, nil)!)
            self.adImageView.image = image
            setupConsentIcons()
        }
    }

    private func setupConsentIcons() {
        let iconWidth = 20
        let iconHeight = 20
        
        if #available(iOS 13.0, *) {
            let lightConfiguration = UIImage.SymbolConfiguration(weight: .light)
            self.crossImageView = UIImageView(image: UIImage(systemName: "xmark.square", withConfiguration: lightConfiguration))
        } else {
            // Fallback on earlier versions
            self.crossImageView = UIImageView(image: UIImage(named: "xmark", in: nil, compatibleWith: nil))
        }
        
        crossImageView!.frame = CGRect(x: Int(adSize!.width) - iconWidth, y: iconHeight/10, width: iconWidth, height: iconHeight)
        crossImageView!.tintColor =  UIColor.init(hexString: "#6C40F7")
        if !isRichMediaAd {
            self.adImageView.addSubview(crossImageView!)
        } else {
            self.adWebView.addSubview(crossImageView!)
        }
        crossImageView!.isUserInteractionEnabled = true
        let tapOnCrossButton = UITapGestureRecognizer(target: self, action: #selector(openAdConsentView))
        crossImageView!.addGestureRecognizer(tapOnCrossButton)

        if #available(iOS 13.0, *) {
            let lightConfiguration = UIImage.SymbolConfiguration(weight: .light)
        self.infoImageView = UIImageView(image: UIImage(systemName: "info.circle", withConfiguration: lightConfiguration))
        } else {
            self.infoImageView = UIImageView(image: UIImage(named: "info", in: nil, compatibleWith: nil))
        }
        infoImageView!.frame = CGRect(x: Int(adSize!.width) - 2*iconWidth, y: iconHeight/10, width: iconWidth, height: iconHeight)
        infoImageView!.tintColor =  UIColor.init(hexString: "#6C40F7")
        if !isRichMediaAd {
            self.adImageView.addSubview(infoImageView!)
        } else {
            self.adWebView.addSubview(infoImageView!)
        }
        infoImageView!.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(startLabelAnimation))
        infoImageView!.addGestureRecognizer(tap)
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
        if !isRichMediaAd {
            self.adImageView.removeFromSuperview()
        } else {
            self.adWebView.removeFromSuperview()
        }
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
        DocereeAdView.self.didLeaveAd = true
        if let url = URL(string: "\(ctaLink ?? "")"), !url.absoluteString.isEmpty {
            customTimer?.stop()
            UIApplication.shared.openURL(url)
            self.removeAllViews()
        }
    }
    
    @objc func appMovedToBackground() {
        customTimer?.stop()
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
        customTimer?.stop()
    }
    
    //will call on dismiss view
    public override func willMove(toWindow newWindow: UIWindow?) {
        if window != nil {
            NotificationCenter.default.removeObserver(self)
            customTimer?.stop()
        }
    }
    
    internal func refresh() {
        self.removeAllViews()
        if docereeAdRequest != nil {
            load(self.docereeAdRequest!)
        }
    }
    
    
    // MARK: Rich Media Setup
    private func initializeRichAds(frame: CGRect?, body: String?) {
        initWebView(frame: frame!)
        let url = URL(fileURLWithPath: "https://adbserver.doceree.com/")
        adWebView.loadHTMLString(body!, baseURL: url)
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

}

 extension DocereeAdView {
     /* Handle HTTP requests from the webview */
     public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
         if navigationAction.navigationType == .linkActivated  {
             if let url = navigationAction.request.url,
                let host = url.host, !host.hasPrefix("www.google.com"),
                UIApplication.shared.canOpenURL(url) {
                 print("click one: ")
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
                     print("click two: ")
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
