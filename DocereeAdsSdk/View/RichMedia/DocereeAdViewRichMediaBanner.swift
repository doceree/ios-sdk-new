import WebKit
import Foundation
import JavaScriptCore
import Photos
import EventKit

public class DocereeAdViewRichMediaBanner: UIViewController, MRAIDDelegate, UINavigationControllerDelegate {
    private var mraidView: WKWebView!
    private var secondaryWebView: WKWebView?
    internal var mraidHandler: MRAIDHandler!
    
    private var defaultPosition: CGPoint?
    private var layoutPosition: String?
    
    private var defaultSize: CGSize? = nil
    private var fallbackSize = CGSize(width: 320, height: 50)
    private let fullScreenSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    
    private var parentController: UIViewController!
    private var previousRootController: UIViewController?
    private var originalRootController: UIViewController?
    
    private var respectSafeArea: Bool = false
    private var isAdMRAIDMedia: Bool = false
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
//
//    public func initialize(parentViewController: UIViewController, position: String, respectSafeArea: Bool = false, renderBodyOverride: Bool, size: AdSize, body: String?, docereeAdView: DocereeAdView?, delegate: DocereeAdViewDelegate?) {
//        initialize(parentViewController: parentViewController, position: position, frame: nil, respectSafeArea: respectSafeArea, renderBodyOverride: renderBodyOverride, size: size, body: body, docereeAdView: docereeAdView, delegate: delegate)
//    }
    
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
        var renderBody2: String = body!
        
        if (!renderBody2.matches()) {
            isAdMRAIDMedia = false
            MRAIDUtilities.validateHTML(&renderBody2)
            let url = URL(fileURLWithPath: "https://adbserver.doceree.com/")
            mraidView.loadHTMLString(renderBody2, baseURL: url)
            originalRootController = UIApplication.shared.delegate?.window??.rootViewController
            if (frame != nil) {
                addAsNormalChild(to: parentViewController, frame: frame!)
            }
            return
        } else {
            isAdMRAIDMedia = true
        }
        
        let url = URL(fileURLWithPath: "https://adbserver.doceree.com/")
        mraidView.loadHTMLString(renderBody2, baseURL: url)
        originalRootController = UIApplication.shared.delegate?.window??.rootViewController
        if (position != nil) {
            addAsChild(to: parentViewController, position: position!)
        } else if(frame != nil) {
            addAsChild(to: parentViewController, frame: frame!)
        }
    }
    
    // MARK: declare visibility var
    
    private var didLeaveApplication: Bool = false

    public override func viewDidLoad() {
//        print("loaded")
        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.appMovedToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.onViewRotate), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    public override func viewDidDisappear(_ animated: Bool) {
//        print("disappear")
        NotificationCenter.default.removeObserver(self)
    }

    @objc func appMovedToBackground() {
        self.didLeaveApplication = true
    }

    @objc func appMovedToForeground() {
        self.didLeaveApplication = false
        self.removeFromParent()
        self.addAsNormalChild(to: self.parentController, frame: frame1!)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.frame.size = CGSize(width: self.size.width, height: self.size.height)
   }
    
    @objc func onViewRotate() {
//        print("rotated")
        self.view.frame.size = CGSize(width: self.size.width, height: self.size.height)
    }
    
    deinit {
        self.view.removeFromSuperview()
    }
    
    //MARK: creating WkWebViewConfiguration here
    
    func webViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController()
        return configuration
    }
    
    private func userContentController() -> WKUserContentController {
        let controller = WKUserContentController()
        controller.addUserScript(viewPortScript())
        return controller
    }
    
    private func viewPortScript() -> WKUserScript {
        let viewPorScript = """
            var meta = document.createElement('meta');
            meta.setAttribute('name', 'viewport');
            meta.setAttribute('content', 'width=device-width');
            meta.setAttribute('initial-scale', '1.0');
            meta.setAttribute('maximum-scale', '1.0');
            meta.setAttribute('minimum-scale', '1.0');
            meta.setAttribute('user-scalable', 'no');
            document.getElementsByTagName('head')[0].appendChild(meta);
        """
        return WKUserScript(source: viewPorScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
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
        mraidHandler = MRAIDHandler()
        mraidHandler.respectsSafeArea = respectSafeArea
        mraidHandler.initialize(parentViewController: self, mraidDelegate: self, isMRAIDCompatible: isAdMRAIDMedia)
        
//        mraidView = WKWebView(frame: frame, configuration: webViewConfiguration())
        mraidView = WKWebView()
        mraidHandler.activeWebView = mraidView
        
        mraidView.uiDelegate = mraidHandler
        mraidView.configuration.allowsInlineMediaPlayback = true
        mraidView.navigationDelegate = mraidHandler
        mraidView.translatesAutoresizingMaskIntoConstraints = false
        mraidView.scrollView.isScrollEnabled = false
        mraidView.isOpaque = true
        mraidView.isUserInteractionEnabled = true
        
        view.addSubview(mraidView)
        
        setInitialConstraints()
    }
    
    private func initSecondaryWebView(_ url: String) {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        secondaryWebView = WKWebView(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        mraidHandler.activeWebView = secondaryWebView!
        mraidHandler.isExpandedView = true
        secondaryWebView!.uiDelegate = mraidHandler
        secondaryWebView!.navigationDelegate = mraidHandler
        secondaryWebView!.isUserInteractionEnabled = true
        secondaryWebView!.translatesAutoresizingMaskIntoConstraints = false
        secondaryWebView?.scrollView.isScrollEnabled = false
        parentController!.view.addSubview(secondaryWebView!)
        if #available(iOS 11.0, *) {
            secondaryWebView!.scrollView.contentInsetAdjustmentBehavior = .never
        }
        NSLayoutConstraint.activate([
            secondaryWebView!.heightAnchor.constraint(equalTo: parentController.view.heightAnchor),
            secondaryWebView!.widthAnchor.constraint(equalTo: parentController.view.widthAnchor)
        ])
        MRAIDUtilities.getExpandedUrlContent(url, completion: { val in
            DispatchQueue.main.async {
                self.mraidHandler.setMRAIDState(States.EXPANDED)
                self.secondaryWebView!.loadHTMLString(val, baseURL:nil)
            }
        })
    }
    
    public func webViewLoaded() {
        if (defaultSize == nil) {
            defaultSize = fallbackSize
        }
        //        setSize(defaultSize!)
        setSize(size.getAdSize())
        if (isAdMRAIDMedia) {
            mraidHandler.setDefaultPosition(CGRect(x: defaultPosition!.x, y: defaultPosition!.y, width: defaultSize!.width, height: defaultSize!.height))
            mraidHandler.setCurrentPosition(CGRect(x: defaultPosition!.x, y: defaultPosition!.y, width: defaultSize!.width, height: defaultSize!.height))
            setPosition(defaultPosition!)
            mraidHandler.setIsViewable(true)
        }
    }
    
    private func addAsChild(to parent: UIViewController, position: String) {
        view.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        parent.view.addSubview(view)
        previousRootController = originalRootController
        parentController.addChild(self)
        let size = CGSize(width: 320, height: 50)
        if (size.width > 0 && size.height > 0) {
            defaultSize = size
            // setting mraid default will happen at setSize
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        layoutPosition = position
        setResizeMask()
        if #available(iOS 11.0, *) {
            mraidView!.scrollView.contentInsetAdjustmentBehavior = .never
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
        self.mraidView.addSubview(crossImageView!)
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
        self.mraidView.addSubview(infoImageView!)
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
        self.mraidView.removeFromSuperview()
        self.view.addSubview(consentUV!)
    }
    
    private func addAsChild(to parent: UIViewController, frame: CGRect) {
        defaultPosition = CGPoint(x: frame.minX, y: frame.minY)
        defaultSize = CGSize(width: frame.width, height: frame.height)
        if (isAdMRAIDMedia) {
            mraidHandler.setDefaultPosition(frame)
            mraidHandler.setCurrentPosition(frame)
        }
    }
    
    private func setResizeMask() {
        let standardSpacing: CGFloat = 8.0
        
        if (layoutPosition! == "center") {
            NSLayoutConstraint.activate([view.centerXAnchor.constraint(equalTo: parentController.view.centerXAnchor),
                                         view.centerYAnchor.constraint(equalTo: parentController.view.centerYAnchor)])
        } else {
            if(layoutPosition!.range(of: "top") != nil) {
                if(mraidHandler.respectsSafeArea) {
                    if #available(iOS 11.0, *) {
                        let guide = parentController.view.safeAreaLayoutGuide
                        NSLayoutConstraint.activate([view.topAnchor.constraint(equalToSystemSpacingBelow: guide.topAnchor, multiplier: 1.0)])
                    } else {
                        NSLayoutConstraint.activate([view.topAnchor.constraint(equalTo: parentController.topLayoutGuide.bottomAnchor, constant: standardSpacing)])
                    }
                } else {
                    NSLayoutConstraint.activate([view.topAnchor.constraint(equalTo: parentController.view.topAnchor)])
                }
                if (layoutPosition!.range(of: "center") != nil) {
                    NSLayoutConstraint.activate([view.centerXAnchor.constraint(equalTo: parentController.view.centerXAnchor)])
                }
            }
            if (layoutPosition!.range(of: "bottom") != nil) {
                if (mraidHandler.respectsSafeArea) {
                    if #available(iOS 11.0, *) {
                        let guide = parentController.view.safeAreaLayoutGuide
                        NSLayoutConstraint.activate([view.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: 0)])
                    } else {
                        NSLayoutConstraint.activate([view.bottomAnchor.constraint(equalTo: parentController.bottomLayoutGuide.topAnchor, constant: standardSpacing)])
                    }
                } else {
                    NSLayoutConstraint.activate([view.bottomAnchor.constraint(equalTo: parentController.view.bottomAnchor)])
                }
                if (layoutPosition!.range(of: "center") != nil) {
                    NSLayoutConstraint.activate([view.centerXAnchor.constraint(equalTo: parentController.view.centerXAnchor)])
                }
            }
            if (layoutPosition!.range(of: "left") != nil) {
                NSLayoutConstraint.activate([view.leftAnchor.constraint(equalTo: parentController.view.leftAnchor)])
                if(layoutPosition!.range(of: "center") != nil) {
                    NSLayoutConstraint.activate([view.centerYAnchor.constraint(equalTo: parentController.view.centerYAnchor)])
                }
            }
            if(layoutPosition!.range(of: "right") != nil) {
                NSLayoutConstraint.activate([view.rightAnchor.constraint(equalTo: parentController.view.rightAnchor)])
                if(layoutPosition!.range(of: "center") != nil) {
                    NSLayoutConstraint.activate([view.centerYAnchor.constraint(equalTo: parentController.view.centerYAnchor)])
                }
            }
        }
    }
    
    @objc func onCloseExpandedClicked(sender: UIButton!) {
        close()
    }
    
    
    func customCloseClicked() {
        close()
    }
    
    func setRootController(_ controller: UIViewController) {
        previousRootController = UIApplication.shared.delegate?.window??.rootViewController
        UIApplication.shared.delegate?.window??.addSubview(controller.view)
        UIApplication.shared.delegate?.window??.rootViewController = controller
    }
    
    // only works when this is the root view controller
    public override var shouldAutorotate: Bool {
        if(mraidHandler.orientationProperties.forceOrientation != nil && mraidHandler.orientationProperties.forceOrientation != Orientations.NONE && UIDevice.current.value(forKey: "orientation") as! Int != Int(mraidHandler.orientationMask!.rawValue)) {
            return true
        }
        return mraidHandler.orientationProperties.allowOrientationChange ?? true
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return mraidHandler.orientationMask
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        var degrees = 0
        switch(UIDevice.current.orientation) {
        case UIDeviceOrientation.portrait:
            degrees = 0
        case UIDeviceOrientation.landscapeLeft:
            degrees = 90
        case UIDeviceOrientation.landscapeRight:
            degrees = -90
        case UIDeviceOrientation.portraitUpsideDown:
            degrees = 180
        default:
            break
        }
        let js = """
        window.__defineGetter__('orientation',function(){return \(degrees);});
        (function(){
        var event = document.createEvent('Events');
        event.initEvent('orientationchange', true, false);
        window.dispatchEvent(event);
        })();
        """
        if (mraidHandler.state == States.RESIZED) {
            close()
        }
        if (mraidHandler.state == States.EXPANDED) {
            UIView.setAnimationsEnabled(false)
            self.mraidHandler.setCurrentPosition(CGRect(x:0, y:0, width:size.width, height:size.height))
            self.mraidHandler.setMRAIDScreenSize(size)
            self.mraidHandler.setMRAIDSizeChanged(to:size)
            coordinator.animate(alongsideTransition: { (_) in }, completion: { _ in
                UIView.setAnimationsEnabled(true)
            })
        }
        
        mraidView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    
    
    // webview should always be the same size as the main view
    private func setInitialConstraints() {
        let webViewSizeConstraints = [
            NSLayoutConstraint(item: view as Any, attribute: .width, relatedBy: .equal, toItem: mraidView, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: view as Any, attribute: .height, relatedBy: .equal, toItem: mraidView, attribute: .height, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: view as Any, attribute: .centerX, relatedBy: .equal, toItem: mraidView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: view as Any, attribute: .centerY, relatedBy: .equal, toItem: mraidView, attribute: .centerY, multiplier: 1.0, constant: 0),
        ]
        view.addConstraints(webViewSizeConstraints)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
//        print("view appeared")
    }
    
    private func delegateNotNil() -> Bool {
        return delegate != nil && docereeAdView != nil
    }
    
    private func setSize(_ size:CGSize ) {
        view.frame = CGRect(x: view.frame.minX, y: view.frame.minY, width: size.width, height: size.height)
        view.removeConstraints(view.constraints)
        setInitialConstraints()
        NSLayoutConstraint.activate([view!.widthAnchor.constraint(equalToConstant: size.width),
                                     view!.heightAnchor.constraint(equalToConstant: size.height)])
        
        if (defaultPosition == nil && layoutPosition != nil) {
            defaultPosition = getPointFromPosition(layoutPosition!)
            mraidHandler.setDefaultPosition(CGRect(x: defaultPosition!.x, y: defaultPosition!.y, width: defaultSize!.width, height: defaultSize!.height))
            mraidHandler.setCurrentPosition(CGRect(x: defaultPosition!.x, y: defaultPosition!.y, width: defaultSize!.width, height: defaultSize!.height))
        }
        mraidHandler.setMRAIDSizeChanged(to:size)
    }
    
    private func setPosition(_ point: CGPoint) {
        view.frame = CGRect(x: point.x, y: point.y, width: view.frame.width, height: view.frame.height)
    }
    
    private func getPointFromPosition(_ pos: String) -> CGPoint {
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        if (pos.range(of: "top") != nil) {
            y = 0
        }
        if (pos.range(of: "bottom") != nil) {
            y = parentController.view.bounds.height - view.bounds.height
        }
        if (pos.range(of: "center") != nil) {
            x = (parentController.view.bounds.width / 2) - (view.bounds.width / 2)
            if(pos == Positions.CENTER) {
                y = (parentController.view.bounds.height / 2) - (view.bounds.height / 2)
            }
        }
        if (pos.range(of: "left") != nil) {
            x = 0
        }
        if (pos.range(of: "right") != nil) {
            x = parentController.view.bounds.width - view.bounds.width
        }
        return CGPoint(x: x, y: y)
    }
    
    private func setFullScreen() {
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        view.removeConstraints(view.constraints)
        setInitialConstraints()
        // handled in mraidHandler
        //        mraidHandler.setCurrentPosition(view.frame)
        //        mraidHandler.setMRAIDSizeChanged(to: fullScreenSize)
    }
    
    //  ---------------------------------------
    //  ------   MRAID DELEGATE PROTOCOl ------
    //  ---------------------------------------
    public func reportDOMSize(_ args: String?) {
        do{
            if (defaultSize == nil && args != nil) {
                let size: Size? = try MRAIDUtilities.deserialize(args!)
                if(size != nil) {
                    if(size!.width == 0 || size!.height == 0) {
                        defaultSize = fallbackSize
                    } else{
                        defaultSize = CGSize(width: size!.width, height: size!.height)
                    }
                }
            } else {
                //TODO args was nil
            }
        } catch {
            // width or height was null.. can't find size.
            if (defaultSize == nil) {
                defaultSize = fallbackSize
            }
        }
    }
    
    public func expand(_ url: String?) {
        if (url != nil) {
            //TODO second webview
            initSecondaryWebView(url!)
        } else {
            if (mraidHandler.state != States.EXPANDED) {
                setFullScreen()
                removeFromParent()
                setRootController(self)
            }
        }
    }
    
    public func open(_ url: String) {
        let browser = MRAIDBrowserWindow()
        browser.initialize()
        browser.loadUrl(url)
        browser.onClose(perform: {() in
            MRAIDUtilities.setRootController(self.originalRootController!)
        })
        MRAIDUtilities.setRootController(browser)
    }
    
    public func resize(to: ResizeProperties) {
        setSize(CGSize(width: to.width!, height: to.height!))
        if(to.allowOffscreen == false) {
            var x = CGFloat(0)
            var y = CGFloat(0)
            let vminX = view.frame.minX
            let vminY = view.frame.minY
            let smaxX = parentController.view.frame.maxX
            let smaxY = parentController.view.frame.maxY
            
            if (vminX <= 0) {
                x = 0
            } else {
                x = min(smaxX - view.bounds.width, vminX)
            }
            
            if (vminY <= 0) {
                y = 0
            } else {
                y = min(smaxY - view.bounds.height, vminY)
            }
            setPosition(CGPoint(x: x, y: y))
            mraidHandler.setCurrentPosition(CGRect(x: Int(x), y: Int(y), width: to.width!, height: to.height!))
        } else {
            setPosition(CGPoint(x: view.frame.minX + CGFloat(to.offsetX!), y: view.frame.minY + CGFloat(to.offsetY!)))
            mraidHandler.setCurrentPosition(CGRect(x: Int(defaultPosition!.x) + to.offsetX!, y: Int(defaultPosition!.y) + to.offsetY!, width: to.width!, height: to.height!))
        }
    }
    
    public func close() {
        if (mraidHandler.state == States.RESIZED) {
            setSize(defaultSize!)
            if (layoutPosition != nil) {
                // we may have rotated by force, or just by user interaction while resized.
                // defualt position may be out of place.
                let point = getPointFromPosition(layoutPosition!)
                setPosition(point)
            } else {
                setPosition(defaultPosition!)
            }
            mraidHandler.setCurrentPosition(CGRect(x: defaultPosition!.x, y: defaultPosition!.y, width: defaultSize!.width, height: defaultSize!.height))
        }
        if (mraidHandler.state == States.EXPANDED) {
            if (mraidHandler.activeWebView == secondaryWebView) {
                mraidHandler.activeWebView = mraidView
                secondaryWebView?.removeFromSuperview()
                secondaryWebView = nil
            } else {
                UIView.setAnimationsEnabled(true)
                // re-enable the old root view controller, and add ourselves back to it.
                view.backgroundColor = nil
                setRootController(originalRootController!)
                parentController.addChild(self)
                parentController.view.addSubview(view)
            }
            setSize(defaultSize!)
            if (layoutPosition != nil) {
                // we may have rotated by force, or just by user interaction while expanded.
                // defualt position may be out of place.
                let point = getPointFromPosition(layoutPosition!)
                setPosition(point)
            } else {
                setPosition(defaultPosition!)
            }
            mraidHandler.setCurrentPosition(CGRect(x: defaultPosition!.x, y: defaultPosition!.y, width: defaultSize!.width, height: defaultSize!.height))
            setResizeMask()
        }
    }
}

extension String {
    func matches() -> Bool {
        let pattern = "<script\\s+[^>]*\\bsrc\\s*=\\s*\\\\?([\\\\\"\\\\'])mraid\\.js\\\\?\\1[^>]*>[^<]*<\\/script>\\n*"
        return (self.range(of: pattern, options: .regularExpression, range: nil, locale: nil) != nil)
    }
}
//
//extension UIApplication{
//    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
//        if let navigationController = controller as? UINavigationController {
//            return topViewController(controller: navigationController.visibleViewController)
//        }
//        if let tabController = controller as? UITabBarController {
//            if let selected = tabController.selectedViewController {
//                return topViewController(controller: selected)
//            }
//        }
//        if let presented = controller?.presentedViewController {
//            return topViewController(controller: presented)
//        }
//        return controller
//    }
//}
