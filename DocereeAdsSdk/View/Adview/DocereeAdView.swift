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
@preconcurrency import WebKit

public final class DocereeAdView: UIView, UIApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    
    @IBOutlet public weak var rootViewController: UIViewController?
    
    //MARK: Properties
    public var docereeAdUnitId: String = String.init()
    public var delegate: DocereeAdViewDelegate?
    public var position: AdPosition = .custom
    
    var cbId: String?
    var docereeAdRequest: DocereeAdRequest?
    
    var adSize: AdSize?
    var ctaLink: String?
    var crossImageView: UIImageView?
    var infoImageView: UIImageView?
    var isRichMediaAd = false
    var customTimer: CustomTimer?
    var viewportTimer: CustomTimer?
    var adWebView: WKWebView!
    var webViewInitialNavigation: WKNavigation?
    var sessionInteractor: OMIDSessionInteractor?
    
    static var didLeaveAd: Bool = false
    var adResponseData: AdResponseNew?
    var totalViewTime = 0
    var savedViewPercentage: Float = 0.0
    var oneSecMrcSent = false
    var viewportPercentage: Float = 90
    var isRefreshing = false
    
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
 
    public convenience init?(with size: String?, and origin: CGPoint, adPosition: AdPosition = .custom) {
        guard let size = size else {
            os_log("Error: AdSize must be provided", log: .default, type: .error)
            return nil
        }

        let parsedSize = getAdSize(for: size)
        guard !(parsedSize is Invalid) else {
            os_log("Error: Invalid ad size", log: .default, type: .error)
            return nil
        }

        let screenWidth = UIScreen.main.bounds.width
        let adjustedWidth = min(parsedSize.width, screenWidth)

        var finalSize = getAddSize(adSize: parsedSize)
        finalSize.width = adjustedWidth

        self.init(frame: CGRect(origin: origin, size: CGSize(width: finalSize.width, height: finalSize.height)))
        self.adSize = finalSize
        self.position = adPosition
        configureLayout()
    }

    
    private func configureLayout() {
        translatesAutoresizingMaskIntoConstraints = (position != .top && position != .bottom)
        clipsToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(DocereeAdView.onImageTouched(_:)))
        self.adImageView.isUserInteractionEnabled = true
        self.adImageView.addGestureRecognizer(tap)
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: adSize?.width ?? 0, height: adSize?.height ?? 0)
    }
    
    //MARK: Public methods
    public func load(_ docereeAdRequest: DocereeAdRequest) {
        guard let adSize = self.adSize else { return }
        let unsupportedPhoneSizes: Set<String> = ["LEADERBOARD", "FULLBANNER"]

        if UIDevice.current.userInterfaceIdiom == .phone,
           unsupportedPhoneSizes.contains(adSize.getAdSizeName()) {
            os_log("Invalid Request. Ad size will not fit on screen", log: .default, type: .error)
            return
        }
        
        totalViewTime = 0
        savedViewPercentage = 0
        self.oneSecMrcSent = false
        self.docereeAdRequest = docereeAdRequest
        let sizeObj = adSize.getAdSize()
        let width = Int(sizeObj.width)
        let height = Int(sizeObj.height)
        let size = "\(width)x\(height)"
        
        let viewPercentage = checkViewability(adView: self)
        if viewPercentage >= viewportPercentage {
            let userId = adResponseData?.userId ?? ""
            fetchAd(size, userId)
        } else {
            self.viewportTimer(adFound: false)
        }
    }

    public override class var requiresConstraintBasedLayout: Bool {
        return true
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
    
    func refresh() {
        self.removeAllViews()
        if let request = docereeAdRequest, parentViewController != nil {
            load(request)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        viewportTimer?.stop()
        customTimer?.stop()
        self.sendViewTime(standard: "mrc", killSession: true)
        adWebView?.navigationDelegate = nil
        adWebView?.uiDelegate = nil
        adWebView?.removeFromSuperview()
        adWebView = nil
    }

}
