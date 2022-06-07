import WebKit
import Foundation
import JavaScriptCore
import Photos
import EventKit

public class DocereeAdViewRichMediaBanner: UIViewController, UINavigationControllerDelegate, WKNavigationDelegate {
    private var adWebView: WKWebView!

    private var parentController: UIViewController!
    private var previousRootController: UIViewController?
    private var originalRootController: UIViewController?
    
    private var respectSafeArea: Bool = false
    private var delegate: DocereeAdViewDelegate?
    private var docereeAdView: DocereeAdView?
    private var frame1: CGRect?
    
    var consentUV: AdConsentUIView?
    
    var crossImageView: UIImageView?
    var infoImageView: UIImageView?
    let iconWidth = 20
    let iconHeight = 20
    
    // MARK: desired size for ads
    private var size: AdSize = Banner()

    public func initialize(parentViewController: UIViewController, frame: CGRect, respectSafeArea: Bool = false, renderBodyOverride: Bool, size: AdSize, body: String?, docereeAdView: DocereeAdView?, delegate: DocereeAdViewDelegate?) {
        initialize(parentViewController: parentViewController, position: nil, frame: frame, respectSafeArea: respectSafeArea,
                   renderBodyOverride: renderBodyOverride, size: size, body: body, docereeAdView: docereeAdView, delegate: delegate)
    }
    
    private func initialize(parentViewController: UIViewController, position: String?, frame: CGRect?, respectSafeArea: Bool = false, renderBodyOverride: Bool, size: AdSize, body: String?, docereeAdView: DocereeAdView?, delegate: DocereeAdViewDelegate?) {
        self.parentController = parentViewController
        self.respectSafeArea = respectSafeArea
        self.size = size
        self.delegate = delegate
        self.docereeAdView = docereeAdView
        
        initBanner(frame: frame!)
        //        MRAIDUtilities.validateHTML(&renderBody)
        let renderBody2: String = body!
        
        let url = URL(fileURLWithPath: "https://adbserver.doceree.com/")
        adWebView.loadHTMLString(renderBody2, baseURL: url)
        originalRootController = UIApplication.shared.delegate?.window??.rootViewController
        if (frame != nil) {
            addAsNormalChild(to: parentViewController, frame: frame!)
        }
 
    }
    
    // MARK: declare visibility var
    
    private var didLeaveApplication: Bool = false

    public override func viewDidLoad() {
//        print("loaded")
    }

    public override func viewDidDisappear(_ animated: Bool) {
//        print("disappear")
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.frame.size = CGSize(width: self.size.width, height: self.size.height)
   }

    deinit {
        self.view.removeFromSuperview()
    }
    
    func initBanner(frame: CGRect) {
        view.backgroundColor = UIColor.white
        self.frame1 = frame
        initWebView(frame: frame)
    }
    
    public override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    private func initWebView(frame: CGRect) {
        adWebView = WKWebView()
        adWebView.configuration.allowsInlineMediaPlayback = true
        adWebView.navigationDelegate = self
        adWebView.translatesAutoresizingMaskIntoConstraints = false
        adWebView.scrollView.isScrollEnabled = false
        adWebView.isOpaque = true
        adWebView.isUserInteractionEnabled = true
        
        view.addSubview(adWebView)
        
        setInitialConstraints()
    }
    
    /* Handle HTTP requests from the webview */
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated  {
//                if DocereeAdView.shouldSendCPC() {
//                    DocereeAdView.cpcCount += 1
//                }
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
    private func addAsNormalChild(to parent: UIViewController, frame: CGRect) {
        view.frame = frame
        parent.view.addSubview(view)
        setupConsentIcons()
    }
    
    private func setupConsentIcons() {

        if #available(iOS 13.0, *) {
            let lightConfiguration = UIImage.SymbolConfiguration(weight: .light)
            self.crossImageView = UIImageView(image: UIImage(systemName: "xmark.square", withConfiguration: lightConfiguration))
        } else {
            // Fallback on earlier versions
            self.crossImageView = UIImageView(image: UIImage(named: "xmark.square", in: nil, compatibleWith: nil))
        }
    
        crossImageView!.frame = CGRect(x: Int(size.width) - iconWidth, y: iconHeight/10, width: iconWidth, height: iconHeight)
        crossImageView!.tintColor =  UIColor.init(hexString: "#6C40F7")
        self.adWebView.addSubview(crossImageView!)
        crossImageView!.isUserInteractionEnabled = true
        let tapOnCrossButton = UITapGestureRecognizer(target: self, action: #selector(openAdConsentView))
        crossImageView!.addGestureRecognizer(tapOnCrossButton)
        
        if #available(iOS 13.0, *) {
            let lightConfiguration = UIImage.SymbolConfiguration(weight: .light)
            self.infoImageView = UIImageView(image: UIImage(systemName: "info.circle", withConfiguration: lightConfiguration))
        } else {
            // Fallback on earlier versions
            self.infoImageView = UIImageView(image: UIImage(named: "info.circle", in: nil, compatibleWith: nil))
        }
        infoImageView!.frame = CGRect(x: Int(size.width) - 2*iconWidth, y: iconHeight/10, width: iconWidth, height: iconHeight)
        infoImageView!.tintColor =  UIColor.init(hexString: "#6C40F7")
        self.adWebView.addSubview(infoImageView!)
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
        placeHolderView.textColor = UIColor(hexString: "#6C40F7")
        placeHolderView.frame = CGRect(x: xCoords, y: yCoords, width: 0, height: (self.infoImageView?.frame.height)!)
        self.infoImageView!.addSubview(placeHolderView)
        placeHolderView.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 2.0, animations: { [self] in
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
        consentUV = AdConsentUIView(with: self.size, frame: frame1!, rootVC: self, adView: self.docereeAdView, isRichMedia: true)
        self.adWebView.removeFromSuperview()
        self.view.addSubview(consentUV!)
    }
    
    // webview should always be the same size as the main view
    private func setInitialConstraints() {
        let webViewSizeConstraints = [
            NSLayoutConstraint(item: view as Any, attribute: .width, relatedBy: .equal, toItem: adWebView, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: view as Any, attribute: .height, relatedBy: .equal, toItem: adWebView, attribute: .height, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: view as Any, attribute: .centerX, relatedBy: .equal, toItem: adWebView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: view as Any, attribute: .centerY, relatedBy: .equal, toItem: adWebView, attribute: .centerY, multiplier: 1.0, constant: 0),
        ]
        view.addConstraints(webViewSizeConstraints)
    }

}
