//
//  AdConsentUIView.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 17/05/22.
//

import UIKit
import WebKit

class AdConsentUIView: UIView {

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
        initialization()
    }
    
    // MARK: Initialize consent view
    private func initialization() {
        guard let adSize = self.adViewSize else { return }
        isMediumRectangle = getAdTypeBySize(adSize: adSize) == AdType.MEDIUMRECTANGLE
        isBanner = getAdTypeBySize(adSize: adSize) == AdType.BANNER
        isLeaderboard = getAdTypeBySize(adSize: adSize) == AdType.LEADERBOARD
        isSmallBanner = getAdTypeBySize(adSize: adSize) == AdType.SMALLBANNER

        consentView = UIView()
        consentView!.backgroundColor = ConsentConstants.backgroundColor
        loadConsentForm1()
    }
    
    // MARK: Load Consent form1
    private func loadConsentForm1() {
        let backIcon = createBackIcon()
        let titleLabel = createTitleLabel(width: frame.width)
        let horizontalStack = createHorizontalStack(backIcon, titleLabel)

        let btnReportAd = createActionButton(title: "Report this Ad", action: #selector(reportAdClicked))
        let btnWhyAd = createActionButton(title: "Why this Ad?", iconName: "info.circle", action: #selector(whyThisClicked), iconOnRight: true)
        
        // stackview
        let buttonStack = UIStackView(arrangedSubviews: [btnReportAd, btnWhyAd])
        buttonStack.axis =  isMediumRectangle ? .vertical : .horizontal
        buttonStack.distribution = isMediumRectangle ? .fillEqually : .fill
        buttonStack.alignment = .center
        buttonStack.spacing = ConsentConstants.defaultSpacing
        if isMediumRectangle {
            btnReportAd.topAnchor.constraint(equalTo: buttonStack.topAnchor, constant: self.adViewFrame!.height * 0.25).isActive = true
        }
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        // vertical stackview
        let verticalStack = UIStackView(arrangedSubviews: [horizontalStack, buttonStack])
        verticalStack.axis = .vertical
        verticalStack.distribution = .fillProportionally
        verticalStack.alignment = .center
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        consentView!.addSubview(verticalStack)
        
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: consentView!.topAnchor),
            verticalStack.bottomAnchor.constraint(equalTo: consentView!.bottomAnchor, constant: isMediumRectangle ? -self.adViewFrame!.height * 0.25 : 0),
            verticalStack.leadingAnchor.constraint(equalTo: consentView!.leadingAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: consentView!.trailingAnchor)
        ])
        
        consentView!.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)
        attachConsentView()
    }

    // MARK: - Attach Consent View
    private func attachConsentView() {
        guard let consent = consentView else { return }
        consent.frame = CGRect(origin: .zero, size: adViewFrame?.size ?? .zero)

        if isRichMedia {
            rootViewController?.view.subviews.forEach { $0.removeFromSuperview() }
            rootViewController?.view.addSubview(consent)
        } else {
            docereeAdView?.addSubview(consent)
        }
    }

    
    // MARK: Load Consent form2
    private func loadConsentForm2() {
        // load back button
        formConsentType = .consentType2
        
        consentView = UIView()
        consentView!.backgroundColor = ConsentConstants.backgroundColor

        let buttonTexts = [
            ("Ad is covering the content of the website.", #selector(adCoveringContentClicked)),
            ("Ad was inappropriate.", #selector(adWasInappropriateClicked)),
            ("Not interested in this ad.", #selector(adNotInterestedClicked))
        ]
        let buttons = buttonTexts.map { createButtonWithText($0.0, action: $0.1) }
        
        // stackview
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = isMediumRectangle ? .vertical : .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = isMediumRectangle ? ConsentConstants.defaultSpacing : ConsentConstants.smallPadding
        stackView.translatesAutoresizingMaskIntoConstraints = false
        if isMediumRectangle {
            buttons[0].topAnchor.constraint(equalTo: stackView.topAnchor, constant: self.adViewFrame!.height * 0.2).isActive = true
        }
        consentView!.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: consentView!.topAnchor, constant: isLeaderboard ? adViewFrame!.height * 0.2 : 0),
            stackView.bottomAnchor.constraint(equalTo: consentView!.bottomAnchor, constant: (isMediumRectangle || isLeaderboard) ? -adViewFrame!.height * 0.2 : 0),
            stackView.leadingAnchor.constraint(equalTo: consentView!.leadingAnchor, constant: isLeaderboard ? ConsentConstants.largePadding : ConsentConstants.smallPadding),
            stackView.trailingAnchor.constraint(equalTo: consentView!.trailingAnchor, constant: isLeaderboard ? -ConsentConstants.largePadding : -ConsentConstants.smallPadding)
        ])

        consentView!.frame = CGRect(x: .zero, y: .zero, width: adViewFrame!.width, height: adViewFrame!.height)
        attachConsentView()
    }

    // MARK: Load Consent form3
    private func loadConsentForm3() {
        formConsentType = .consentType3
        consentView = UIView()
        consentView?.backgroundColor = ConsentConstants.backgroundColor

        let buttonTexts = [
            ("I'm not interested\n in seeing ads for this product.", #selector(adNotInterestedClicked1)),
            ("I'm not interested\n in seeing ads for this brand.", #selector(adNotInterestedClicked2)),
            ("I'm not interested in seeing ads for this category.", #selector(adNotInterestedClicked3)),
            ("I'm not interested in seeing ads from pharmaceutical brands.", #selector(adNotInterestedClicked4))
        ]
        
        let buttons = buttonTexts.map { createButtonWithText($0.0, action: $0.1) }
        
        let horizontalStackView = UIStackView(arrangedSubviews: buttons)
        horizontalStackView.axis = isMediumRectangle ? .vertical : .horizontal
        horizontalStackView.distribution = .fillEqually
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = isMediumRectangle ? 6.0 : 4.0
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        
        consentView?.addSubview(horizontalStackView)
        
        if isMediumRectangle {
            buttons[0].topAnchor.constraint(equalTo: horizontalStackView.topAnchor, constant: self.adViewFrame!.height * 0.1).isActive = true
        }

        NSLayoutConstraint.activate([
            horizontalStackView.topAnchor.constraint(equalTo: consentView!.topAnchor),
            horizontalStackView.bottomAnchor.constraint(equalTo: consentView!.bottomAnchor, constant: isMediumRectangle ? -adViewFrame!.height * 0.1 : 0),
            horizontalStackView.leadingAnchor.constraint(equalTo: consentView!.leadingAnchor, constant: ConsentConstants.smallPadding),
            horizontalStackView.trailingAnchor.constraint(equalTo: consentView!.trailingAnchor, constant: -ConsentConstants.smallPadding)
        ])

        consentView?.frame = CGRect(x: 0, y: 0, width: adViewFrame!.width, height: adViewFrame!.height)
        attachConsentView()
    }

    @objc func whyThisClicked(_ sender: UITapGestureRecognizer) {
        DocereeAdView.self.didLeaveAd = true
        let whyThisLink = "https://support.doceree.com/hc/en-us/articles/360050646094-Why-this-Ad-"
        if let url = URL(string: "\(whyThisLink)"), !url.absoluteString.isEmpty {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @objc func reportAdClicked(_ sender: UITapGestureRecognizer) {
        loadConsentForm2()
    }
    
    @objc func backButtonClicked(_ sender: UITapGestureRecognizer) {
        consentView?.removeFromSuperview()
    }
    
    func removeAllViews() {
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

}

