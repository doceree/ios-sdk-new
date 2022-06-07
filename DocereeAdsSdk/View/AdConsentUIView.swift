//
//  AdConsentUIView.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 17/05/22.
//

import UIKit
import WebKit

class AdConsentUIView: UIView {
    
    // MARK: Properties
    var requestHttpHeaders = RestEntity()
    var urlQueryParameters = RestEntity()
    var httpBodyParameters = RestEntity()
    var httpBody: Data?
    
    // MARK: private vars
    private var consentView: UIView?
    
    var docereeAdView: DocereeAdView?
    
    var isRichMedia: Bool = false

    var isMediumRectangle: Bool = false
    var isBanner: Bool = false
    var isLeaderboard: Bool = false
    var isSmallBanner: Bool = false
     
    var adViewSize: AdSize?
    
    var adViewFrame: CGRect?
    var rootViewController: UIViewController?
    
    var formConsentType: ConsentType = .consentType2
    
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init?(with adSize: AdSize, frame: CGRect, rootVC: UIViewController?, adView: DocereeAdView?, isRichMedia: Bool) {
        self.init()
        adViewSize = adSize
        adViewFrame = frame
        rootViewController = rootVC
        docereeAdView = adView
        self.isRichMedia = isRichMedia
        isMediumRectangle = getAdTypeBySize(adSize: self.adViewSize!) == AdType.MEDIUMRECTANGLE
        isBanner = getAdTypeBySize(adSize: self.adViewSize!) == AdType.BANNER
        isLeaderboard = getAdTypeBySize(adSize: self.adViewSize!) == AdType.LEADERBOARD
        isSmallBanner = getAdTypeBySize(adSize: self.adViewSize!) == AdType.SMALLBANNER
        loadConsentForm1()
    }
    
    // MARK: Initialize AdConsentUIView
    
    // MARK: Horizontal Containers
    
    // MARK: Vertical Containers
    
    // MARK: Load Consent form1
    private func loadConsentForm1() {
        
        var backButtonUIImageView: UIImageView?
        consentView = UIView()
        consentView!.backgroundColor = greyBackgroundColor

        let iconSize: CGFloat = 15.0
        let titleHeight: CGFloat = 15.0
        
        let buttonWidth: CGFloat = isMediumRectangle ? self.adViewFrame!.width * 0.8 : self.adViewFrame!.width * 0.4
        let buttonHeight: CGFloat = isMediumRectangle ? self.adViewFrame!.height * 0.2 : self.adViewFrame!.height/2
        let buttonLabelFontSize: CGFloat = textFontSize12
 
        var backArrowUIImage: UIImage? = UIImage()
        
        if #available(iOS 13.0, *) {
            let lightConfiguration = UIImage.SymbolConfiguration(pointSize: 5, weight: .light, scale: .small)
            backButtonUIImageView = UIImageView(image: UIImage(systemName: "arrow.backward", withConfiguration: lightConfiguration))
        } else {
            // Fallback on earlier versions

            backArrowUIImage = backArrowUIImage!.resizeImage(image: UIImage(named: "backarrow", in: nil, compatibleWith: nil)!, targetSize: CGSize(width: iconSize, height: iconSize))!
            backButtonUIImageView = UIImageView(image: backArrowUIImage)
        }
        backButtonUIImageView!.contentMode = .scaleAspectFit
        backButtonUIImageView!.tintColor = purpleColor
        backButtonUIImageView!.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        backButtonUIImageView!.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        backButtonUIImageView!.isUserInteractionEnabled = true
        let backButtonUITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backButtonClicked))
        backButtonUIImageView!.addGestureRecognizer(backButtonUITapGestureRecognizer)
        
        let titleView = UILabel()
        titleView.text = "Ads by doceree"
        titleView.font = .systemFont(ofSize: textFontSize12)
        titleView.textColor = purpleColor
        titleView.widthAnchor.constraint(equalToConstant: self.adViewFrame!.width).isActive = true
        titleView.heightAnchor.constraint(equalToConstant: titleHeight).isActive = true
        titleView.textAlignment = .center
        
        // horizontal stackview 1
        let horizontalStackView1 = UIStackView()
        horizontalStackView1.axis = .horizontal
        horizontalStackView1.distribution = UIStackView.Distribution.equalSpacing
        horizontalStackView1.alignment = .fill
        
        horizontalStackView1.addArrangedSubview(backButtonUIImageView!)
        horizontalStackView1.addArrangedSubview(titleView)
        horizontalStackView1.translatesAutoresizingMaskIntoConstraints = false
        
        consentView!.addSubview(horizontalStackView1)
        
        let btnReportAd = UIButton()
        btnReportAd.setTitle("Report this Ad", for: .normal)
        btnReportAd.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        btnReportAd.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        btnReportAd.setTitleColor(blackColor, for: .normal)
        btnReportAd.backgroundColor = whiteColor
        btnReportAd.titleLabel?.font = .systemFont(ofSize: buttonLabelFontSize) // UIFont(name: YourfontName, size: 12)
        btnReportAd.translatesAutoresizingMaskIntoConstraints = false
        btnReportAd.isUserInteractionEnabled = true
        let adReportTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(reportAdClicked))
        btnReportAd.addGestureRecognizer(adReportTapGestureRecognizer)
        
        
        var infoImage: UIImage?
        let btnWhyThisAd = UIButton()
        btnWhyThisAd.setTitle("Why this Ad?", for: .normal)
        if #available(iOS 13.0, *) {
            let lightConfigurationWithSmallScale = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .light, scale: .small)
            infoImage = UIImage(systemName: "info.circle", withConfiguration: lightConfigurationWithSmallScale)!
            infoImage!.withTintColor(purpleColor)
        } else {
            // Fallback on earlier versions
            infoImage = infoImage?.resizeImage(image: UIImage(named: "info", in: nil, compatibleWith: nil)!.imageWithColor(UIColor.purple)!, targetSize: CGSize(width: iconSize, height: iconSize))

        }
        btnWhyThisAd.setImage(infoImage, for: .normal)
        btnWhyThisAd.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        btnWhyThisAd.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        btnWhyThisAd.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        btnWhyThisAd.setTitleColor(blackColor, for: .normal)
        btnWhyThisAd.backgroundColor = whiteColor
        btnWhyThisAd.titleLabel?.font = .systemFont(ofSize: buttonLabelFontSize) // UIFont(name: YourfontName, size: 12)
        btnWhyThisAd.semanticContentAttribute = .forceRightToLeft
        btnWhyThisAd.translatesAutoresizingMaskIntoConstraints = false
        btnWhyThisAd.isUserInteractionEnabled = true
        let whyThisTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(whyThisClicked))
        btnWhyThisAd.addGestureRecognizer(whyThisTapGestureRecognizer)
        
        // horizontal stackview 2
        let horizontalStackView2 = UIStackView()
        horizontalStackView2.axis =  self.isMediumRectangle ? .vertical : .horizontal
        horizontalStackView2.distribution = self.isMediumRectangle ? .fillEqually : .fill
        horizontalStackView2.alignment = .center
        horizontalStackView2.spacing = 8.0
        horizontalStackView2.addArrangedSubview(btnReportAd)
        horizontalStackView2.addArrangedSubview(btnWhyThisAd)
        
        if isMediumRectangle {
            btnReportAd.topAnchor.constraint(equalTo: horizontalStackView2.topAnchor, constant: self.adViewFrame!.height * 0.25).isActive = true
        }
        
        horizontalStackView2.translatesAutoresizingMaskIntoConstraints = false
        
        // vertical stackview
        
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.distribution = .fillProportionally
        verticalStackView.alignment = .center
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.addArrangedSubview(horizontalStackView1)
        verticalStackView.addArrangedSubview(horizontalStackView2)
        
        consentView!.addSubview(verticalStackView)
        
        verticalStackView.topAnchor.constraint(equalTo: consentView!.topAnchor, constant: 0).isActive = true
        verticalStackView.bottomAnchor.constraint(equalTo: consentView!.bottomAnchor, constant: self.isMediumRectangle ? -self.adViewFrame!.height * 0.25 : 0).isActive = true
        verticalStackView.leadingAnchor.constraint(equalTo: consentView!.leadingAnchor, constant: 0).isActive = true
        verticalStackView.trailingAnchor.constraint(equalTo: consentView!.trailingAnchor, constant: 0).isActive = true
        
        consentView!.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)
        
        if (!self.isRichMedia) {
            self.docereeAdView!.addSubview(consentView!)
        } else {
            for v in rootViewController!.view.subviews {
                v.removeFromSuperview()
            }
            consentView!.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)
            self.rootViewController?.view.addSubview(consentView!)
        }
    }

    // MARK: Load Consent form2
    private func loadConsentForm2() {
        // load back button
        formConsentType = .consentType2
        
        consentView = UIView()
        consentView!.backgroundColor = greyBackgroundColor

        let btnAdCoveringContent = createButtonWithText("Ad is covering the content of the website.")
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(adCoveringContentClicked))
        btnAdCoveringContent.addGestureRecognizer(tap1)
        
        let btnAdInappropriate = createButtonWithText("Ad was inappropriate.")
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(adWasInappropriateClicked))
        btnAdInappropriate.addGestureRecognizer(tap2)
        
        let btnAdNotInterested = createButtonWithText("Not interested in this ad.")
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(adNotInterestedClicked))
        btnAdNotInterested.addGestureRecognizer(tap3)
        
        // horizontal stackview 2
        let horizontalStackView2 = UIStackView()
        horizontalStackView2.axis = isMediumRectangle ? .vertical : .horizontal
        horizontalStackView2.distribution = .fillEqually
        horizontalStackView2.alignment = .center
        horizontalStackView2.spacing = self.isMediumRectangle ? 8.0 : 4.0
        horizontalStackView2.addArrangedSubview(btnAdCoveringContent)
        horizontalStackView2.addArrangedSubview(btnAdInappropriate)
        horizontalStackView2.addArrangedSubview(btnAdNotInterested)
        horizontalStackView2.translatesAutoresizingMaskIntoConstraints = false

        if isMediumRectangle {
            btnAdCoveringContent.topAnchor.constraint(equalTo: horizontalStackView2.topAnchor, constant: self.adViewFrame!.height * 0.2).isActive = true
        }
        
        consentView!.addSubview(horizontalStackView2)
        
        horizontalStackView2.topAnchor.constraint(equalTo: consentView!.topAnchor, constant: self.isLeaderboard ? self.adViewFrame!.height * 0.2 : 0).isActive = true
        horizontalStackView2.bottomAnchor.constraint(equalTo: consentView!.bottomAnchor, constant: (self.isMediumRectangle || self.isLeaderboard) ? -self.adViewFrame!.height * 0.2 : 0).isActive = true
        horizontalStackView2.leadingAnchor.constraint(equalTo: consentView!.leadingAnchor, constant: self.isLeaderboard ? 32 :  4).isActive = true
        horizontalStackView2.trailingAnchor.constraint(equalTo: consentView!.trailingAnchor, constant: self.isLeaderboard ? -32 : -4).isActive = true
  
        consentView!.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)

        if (!self.isRichMedia) {
            self.docereeAdView!.addSubview(consentView!)
        } else {
            for v in rootViewController!.view.subviews {
                v.removeFromSuperview()
            }
            consentView!.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)
            self.rootViewController?.view.addSubview(consentView!)
        }
    }

    // MARK: Load Consent form3
    private func loadConsentForm3() {
        
        formConsentType = .consentType3
        
        consentView = UIView()
        consentView!.backgroundColor = greyBackgroundColor
      
        let btn1 = createButtonWithText("I'm not interested\n in seeing ads for this product.")
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(adNotInterestedClicked1))
        btn1.addGestureRecognizer(tap1)
        
        let btn2 = createButtonWithText("I'm not interested\n in seeing ads for this brand.")
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(adNotInterestedClicked2))
        btn2.addGestureRecognizer(tap2)
        
        let btn3 = createButtonWithText("I'm not interested in seeing ads for this category.")
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(adNotInterestedClicked3))
        btn3.addGestureRecognizer(tap3)
        
        let btn4 = createButtonWithText("I'm not interested in seeing ads from pharmaceutical brands.")
        let tap4 = UITapGestureRecognizer(target: self, action: #selector(adNotInterestedClicked4))
        btn4.addGestureRecognizer(tap4)
        
        // horizontal stackview 2
        let horizontalStackView2 = UIStackView()
        horizontalStackView2.axis = self.isMediumRectangle ? .vertical : .horizontal
        horizontalStackView2.distribution = .fillEqually
        horizontalStackView2.alignment = .center
        horizontalStackView2.spacing = self.isMediumRectangle ? 6.0 : 4.0
        horizontalStackView2.addArrangedSubview(btn1)
        horizontalStackView2.addArrangedSubview(btn2)
        horizontalStackView2.addArrangedSubview(btn3)
        horizontalStackView2.addArrangedSubview(btn4)
        horizontalStackView2.translatesAutoresizingMaskIntoConstraints = false
        
        if isMediumRectangle {
            btn1.topAnchor.constraint(equalTo: horizontalStackView2.topAnchor, constant: self.adViewFrame!.height * 0.1).isActive = true
        }
        
        consentView!.addSubview(horizontalStackView2)
        
        horizontalStackView2.topAnchor.constraint(equalTo: consentView!.topAnchor, constant: 0).isActive = true
        horizontalStackView2.bottomAnchor.constraint(equalTo: consentView!.bottomAnchor, constant: self.isMediumRectangle ?
                                                        -self.adViewFrame!.height * 0.1 : 0).isActive = true
        horizontalStackView2.leadingAnchor.constraint(equalTo: consentView!.leadingAnchor, constant: 4).isActive = true
        horizontalStackView2.trailingAnchor.constraint(equalTo: consentView!.trailingAnchor, constant: -4).isActive = true
        
        consentView!.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)

        if (!self.isRichMedia) {
            self.docereeAdView!.addSubview(consentView!)
        } else {
            for v in rootViewController!.view.subviews{
                v.removeFromSuperview()
            }
            consentView!.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)
            self.rootViewController?.view.addSubview(consentView!)
        }
    }
    
    func createButtonWithText(_ text: String) -> UIButton {
        
        let buttonWidth: CGFloat = getButtonSizes().0
        let buttonHeight: CGFloat = getButtonSizes().1
        let buttonLabelFontSize: CGFloat = getButtonSizes().2
 
        let btnAdCoveringContent = UIButton()
        btnAdCoveringContent.setTitle(text, for: .normal)
        btnAdCoveringContent.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        btnAdCoveringContent.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        btnAdCoveringContent.setTitleColor(blackColor, for: .normal)
        btnAdCoveringContent.backgroundColor = whiteColor
        btnAdCoveringContent.titleLabel?.lineBreakMode = .byWordWrapping
        btnAdCoveringContent.titleLabel?.textAlignment = .center
        btnAdCoveringContent.titleLabel?.font = .systemFont(ofSize: buttonLabelFontSize) // UIFont(name: YourfontName, size: 12)
        btnAdCoveringContent.translatesAutoresizingMaskIntoConstraints = false
        btnAdCoveringContent.isUserInteractionEnabled = true
        
        return btnAdCoveringContent
    }
    
    func getButtonSizes() -> (CGFloat, CGFloat, CGFloat) {
        if formConsentType == .consentType2 {
            let buttonWidth: CGFloat = isMediumRectangle ? self.adViewFrame!.width * 0.8 : self.adViewFrame!.width * 0.3
            let buttonHeight: CGFloat = self.adViewFrame!.height * 0.8
            let textFontSize: CGFloat = (self.isBanner || self.isSmallBanner) ? textFontSize10 : textFontSize12
            return (buttonWidth, buttonHeight, textFontSize)
        } else if formConsentType == .consentType3 {
            let buttonWidth: CGFloat = isMediumRectangle ? self.adViewFrame!.width * 0.8 : self.adViewFrame!.width * 0.4
            let buttonHeight: CGFloat = self.adViewFrame!.height * 0.9
            let textFontSize: CGFloat = (self.isBanner || self.isSmallBanner) ? textFontSize8 : textFontSize12
            return (buttonWidth, buttonHeight, textFontSize)
        }
        
        return (0, 0, 0)
    }
    
    // load feedback
    private func loadAdConsentFeedback(_ adblockLevel: String) {
        self.removeAllViews()
        let consentView: UIView = UIView()
        consentView.frame = CGRect(x: 0.0, y: 0.0, width: self.adViewSize!.width, height: self.adViewSize!.height)
        consentView.backgroundColor = greyBackgroundColor
        
        let titleView = UILabel()
        titleView.text = "Thank you for reporting this to us. \nYour feedback will help us improve. \nThis ad by doceree will now be closed."
        
        titleView.font = titleView.font.withSize(textFontSize12)
        titleView.textColor = blackColor
        titleView.frame = consentView.frame
        titleView.center.x = consentView.center.x
        titleView.center.y = consentView.center.y
        titleView.textAlignment = .center
        titleView.lineBreakMode = .byWordWrapping
        titleView.numberOfLines = 3
        consentView.addSubview(titleView)
        consentView.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)

        if (!self.isRichMedia) {
            self.docereeAdView!.addSubview(consentView)
        } else {
            for v in rootViewController!.view.subviews{
                v.removeFromSuperview()
            }
            consentView.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)
            self.rootViewController?.view.addSubview(consentView)
        }
        
        UIView.animate(withDuration: 3, delay: 0.5, options: .curveEaseIn, animations: {
            consentView.alpha = 0
        }) { [self] _ in
            self.docereeAdView?.refresh()
            do {
                let rawdata = try Data(contentsOf: URL(fileURLWithPath: PlatformArchivingUrl.path))
                if let plaformUid = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(rawdata) as! String? {
                    self.sendAdBlockRequest(self.docereeAdView!.cbId!, adblockLevel, plaformUid, self.docereeAdView!.docereeAdUnitId)
                }
            } catch {
                print("Couldn't read file")
            }
        }
    }
    
    @objc func whyThisClicked(_ sender: UITapGestureRecognizer) {
        DocereeAdView.self.didLeaveAd = true
        let whyThisLink = "https://support.doceree.com/hc/en-us/articles/360050646094-Why-this-Ad-"
        if let url = URL(string: "\(whyThisLink)"), !url.absoluteString.isEmpty {
            UIApplication.shared.openURL(url)
        }
    }
    
    @objc func reportAdClicked(_ sender: UITapGestureRecognizer) {
        // open second consent screen
        loadConsentForm2()
    }
    
    @objc func backButtonClicked(_ sender: UITapGestureRecognizer) {
        // back button pressed
        self.docereeAdView?.refresh()
        // remove this view and refresh ad
    }
    
    private func removeAllViews() {
        for v in self.consentView!.subviews {
            v.removeFromSuperview()
        }
    }
    
    @objc func adCoveringContentClicked(_ sender: UITapGestureRecognizer) {
        loadAdConsentFeedback(BlockLevel.AdCoveringContent.info.blockLevelCode)
    }
    
    @objc func adWasInappropriateClicked(_ sender: UITapGestureRecognizer) {
        loadAdConsentFeedback(BlockLevel.AdWasInappropriate.info.blockLevelCode)
    }
    
    @objc func adNotInterestedClicked(_ sender: UITapGestureRecognizer) {
        loadConsentForm3()
    }
    
    @objc func adNotInterestedClicked1(_ sender: UITapGestureRecognizer) {
        loadAdConsentFeedback(BlockLevel.NotInterestedInCampaign.info.blockLevelCode)
    }
    
    @objc func adNotInterestedClicked2(_ sender: UITapGestureRecognizer) {
        loadAdConsentFeedback(BlockLevel.NotInterestedInBrand.info.blockLevelCode)
    }
    
    @objc func adNotInterestedClicked3(_ sender: UITapGestureRecognizer) {
        loadAdConsentFeedback(BlockLevel.NotInterestedInBrandType.info.blockLevelCode)
    }
    
    @objc func adNotInterestedClicked4(_ sender: UITapGestureRecognizer) {
        loadAdConsentFeedback(BlockLevel.NotInterestedInClientType.info.blockLevelCode)
    }
    
    internal func sendAdBlockRequest(_ advertiserCampID: String?, _ blockLevel: String?, _ platformUid: String?, _ publisherACSID: String?){
        if ((advertiserCampID ?? "").isEmpty || (blockLevel ?? "").isEmpty || (platformUid ?? "").isEmpty || (publisherACSID ?? "").isEmpty) {
            return
        }
        let ua: String = UAString.init().UAString()
        // headers
        self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
        self.requestHttpHeaders.add(value: UAString.init().UAString(), forKey: Header.header_user_agent.rawValue)
        
        // query params
        self.httpBodyParameters.add(value: advertiserCampID!, forKey: AdBlockService.advertiserCampID.rawValue)
        self.httpBodyParameters.add(value: blockLevel!, forKey: AdBlockService.blockLevel.rawValue)
        self.httpBodyParameters.add(value: platformUid!, forKey: AdBlockService.platformUid.rawValue)
        self.httpBodyParameters.add(value: publisherACSID!, forKey: AdBlockService.publisherACSID.rawValue)
        
        let body = httpBodyParameters.allValues()
//        print("AdBlock request passed is \(body)")
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        var components = URLComponents()
        components.scheme = "https"
        components.host = getDocTrackerHost(type: EnvironmentType.Prod)
        components.path = getPath(methodName: Methods.AdBlock)
        let adBlockEndPoint: URL = components.url!
        var request: URLRequest = URLRequest(url: adBlockEndPoint)
        request.setValue(ua, forHTTPHeaderField: Header.header_user_agent.rawValue)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // set headers
        for header in requestHttpHeaders.allValues() {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        request.httpMethod = HttpMethod.post.rawValue
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch{
            return
        }
        let task = session.dataTask(with: request){(data, response, error) in
            guard data != nil else { return }
            let urlResponse = response as! HTTPURLResponse
            print("Test: Send Block")
            print(urlResponse.statusCode)
        }
        task.resume()
    }
    
}

