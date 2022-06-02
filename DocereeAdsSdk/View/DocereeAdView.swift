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

public final class DocereeAdView: UIView, UIApplicationDelegate {
    
    //MARK: Properties
    public var docereeAdUnitId: String = String.init()
    public var delegate: DocereeAdViewDelegate?
    public var position: AdPosition = .custom
    var ctaLink: String?
    var cbId: String?
    static var didLeaveAd: Bool = false
    private var docereeAdRequest: DocereeAdRequest?

    var crossImageView: UIImageView?
    var infoImageView: UIImageView?

    var richMediaBanner: DocereeAdViewRichMediaBanner?
    
    @IBOutlet public weak var rootViewController: UIViewController?
    
    var adSize: AdSize?
    
    var customTimer: CustomTimer?
    lazy var adImageView: UIImageView = {
        let adImageView = UIImageView()
        adImageView.translatesAutoresizingMaskIntoConstraints = false
        return adImageView
    }()
    
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(adImageView)
        setUpLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(adImageView)
        setUpLayout()
    }
 
    public convenience init?(with size: String?, and origin: CGPoint, adPosition: AdPosition?){
        self.init(with: size, adPosition: adPosition!)
        
        adSize = getAdSize(for: size)
        if adSize!.width > UIScreen.main.bounds.width {
            self.adSize?.width = UIScreen.main.bounds.width
        }
        self.init(with: adSize, and: origin, adPosition: adPosition!)
    }
    
    public convenience init?(with size: String?, adPosition: AdPosition) {
        self.init()
        if size == nil || size?.count == 0 {
            if #available(iOS 10.0, *) {
                os_log("Error: Please provide a valid size!", log: .default, type: .error)
            } else {
                // Fallback on earlier versions
            }
            return
        }
        adSize = getAdSize(for: size)
        if adSize is Invalid {
            if #available(iOS 10.0, *) {
                print("adSize:", adSize as Any)
                os_log("Error Test: Invalid size!", log: .default, type: .error)
            } else {
                // Fallback on earlier versions
            }
            return
        }
        adSize = getAdSize(for: size)
        if adSize!.width > UIScreen.main.bounds.width {
            self.adSize?.width = UIScreen.main.bounds.width
        }
        self.init(with: adSize, adPosition: adPosition)
    }
   
    private convenience init(with adSize: AdSize?, adPosition: AdPosition) {
        self.init(frame: CGRect(x: .zero, y: .zero, width: (adSize?.width)!, height: (adSize?.height)!))
        if adSize == nil {
            if #available(iOS 10.0, *) {
                os_log("Error: AdSize must be provided", log: .default, type: .error)
            } else {
                // Fallback on earlier versions
            }
        } else{
            if adSize is Banner {
                self.adSize = Banner()
            } else if adSize is FullBanner {
                self.adSize = FullBanner()
            } else if adSize is MediumRectangle {
                self.adSize = MediumRectangle()
            } else if adSize is LargeBanner {
                self.adSize = LargeBanner()
            } else if adSize is LeaderBoard {
                self.adSize = LeaderBoard()
            } else if adSize is SmallBanner {
                self.adSize = SmallBanner()
            } else {
                self.adSize = Banner()
            }
        }
        self.position = adPosition
        addSubview(adImageView)
        setUpLayout()
    }
    
    private convenience init(with adSize: AdSize?, and origin: CGPoint, adPosition: AdPosition){
        self.init(frame: CGRect(x: origin.x, y: origin.y, width: (adSize?.width)!, height: (adSize?.height)!))
        if adSize == nil {
            if #available(iOS 10.0, *) {
                os_log("Error: AdSize must be provided", log: .default, type: .error)
            } else {
                // Fallback on earlier versions
            }
        } else{
            self.adSize = adSize
        }
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
        //        todo set image here
        self.docereeAdRequest = docereeAdRequest
        let queue = OperationQueue()
        let operation1 = BlockOperation(block: {
            let width: Int = Int((self.adSize?.getAdSize().width)!)
            let height: Int = Int((self.adSize?.getAdSize().height)!)
            let size = "\(width)x\(height)"
            
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
            
            docereeAdRequest.requestAd(self.docereeAdUnitId, size){ (results, isRichMediaAd) in
                if let data = results.data {
                    self.createAdUI(data: data, isRichMediaAd: isRichMediaAd)
                } else {
                    self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: DocereeAdRequestError.failedToCreateRequest)
                    self.removeAllViews()
                }
            }
        })
        queue.addOperation(operation1)
        startTimer()
    }
    
    //MARK: Private methods
    
    private func startTimer() {
        customTimer?.stop()
        customTimer = CustomTimer { (seconds) in
            // do whatever you want
//            print("seconds: ", seconds)
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
                if (adResponseData.sourceURL ?? "").isEmpty{
                    self.removeAllViews()
                    return
                }
//                let imageUrl = adResponseData.sourceURL
                self.cbId = adResponseData.CBID?.components(separatedBy: "_")[0]
                self.docereeAdUnitId = adResponseData.DIVID!
                self.ctaLink = adResponseData.ctaLink
                let isImpressionLinkNullOrEmpty: Bool = (adResponseData.impressionLink ?? "").isEmpty
                if (!isImpressionLinkNullOrEmpty) {
                    self.docereeAdRequest?.sendImpression(impressionUrl: adResponseData.impressionLink!)
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
                if self.delegate != nil{
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
            if let url = URL(string: urlString){
                do{
                    let htmlContent = try String(contentsOf: url)
                    var refinedHtmlContent = htmlContent.withReplacedCharacter("<head>", by: "<head><style>html,body{padding:0;margin:0;}</style><base href=" + (urlString.components(separatedBy: "unzip")[0]) + "unzip/" + "target=\"_blank\">")
                    if (self.ctaLink != nil && self.ctaLink!.count > 0){
                        refinedHtmlContent = refinedHtmlContent.replacingOccurrences(of: "[TRACKING_LINK]", with: self.ctaLink!)
                    }
                    let body: String = refinedHtmlContent
                    if (body.count == 0) {
                        return
                    }
                    DispatchQueue.main.async {
                        self.richMediaBanner = DocereeAdViewRichMediaBanner()
                        //                                    banner.initialize(parentViewController:self.rootViewController!, position:"bottom-center", respectSafeArea:true, renderBodyOverride: true, size: self.adSize!, body: body)
                        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
                        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.willMoveToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
                        NotificationCenter.default.setObserver(observer: self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
                        self.richMediaBanner!.initialize(parentViewController: self.rootViewController!, frame: self.frame, renderBodyOverride: false, size: self.adSize!, body: body, docereeAdView: self, delegate: self.delegate)
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
        self.adImageView.addSubview(crossImageView!)
        crossImageView!.isUserInteractionEnabled = true
        let tapOnCrossButton = UITapGestureRecognizer(target: self, action: #selector(openAdConsentView))
        crossImageView!.addGestureRecognizer(tapOnCrossButton)

        if #available(iOS 13.0, *){
            let lightConfiguration = UIImage.SymbolConfiguration(weight: .light)
        self.infoImageView = UIImageView(image: UIImage(systemName: "info.circle", withConfiguration: lightConfiguration))
        } else {
            self.infoImageView = UIImageView(image: UIImage(named: "info", in: nil, compatibleWith: nil))
        }
        infoImageView!.frame = CGRect(x: Int(adSize!.width) - 2*iconWidth, y: iconHeight/10, width: iconWidth, height: iconHeight)
        infoImageView!.tintColor =  UIColor.init(hexString: "#6C40F7")
        self.adImageView.addSubview(infoImageView!)
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
            placeHolderView.backgroundColor = UIColor(named: "#F2F2F2")
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
        let consentUV = AdConsentUIView(with: self.adSize!, frame: self.frame, rootVC: self.rootViewController!, adView: self, isRichMedia: false)
        self.adImageView.removeFromSuperview()
        self.addSubview(consentUV!)
    }
    
    public override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    func removeAllViews() {
        DispatchQueue.main.async {
            for v in self.subviews{
                v.removeFromSuperview()
            }
            if(self.richMediaBanner != nil) {
                self.richMediaBanner?.view.removeFromSuperview()
            }
        }
    }
    
    //Mark: Action method
    @objc func onImageTouched(_ sender: UITapGestureRecognizer) {
        DocereeAdView.self.didLeaveAd = true
        if let url = URL(string: "\(ctaLink ?? "")"), !url.absoluteString.isEmpty {
            customTimer?.stop()
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if delegate != nil {
            delegate?.docereeAdViewWillDismissScreen(self)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        customTimer?.stop()
    }
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        if window != nil {
            NotificationCenter.default.removeObserver(self)
            customTimer?.stop()
        }
    }
    
    func refresh() {
        self.removeAllViews()
        if docereeAdRequest != nil {
            load(self.docereeAdRequest!)
        }
    }
}

//fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
//    switch (lhs, rhs) {
//    case let (l?, r?):
//        return l < r
//    case (nil, _?):
//        return true
//    default:
//        return false
//    }
//}
