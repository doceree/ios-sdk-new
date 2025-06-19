//
//  AdConsentUIFactory.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 17/06/25.
//

import UIKit

extension AdConsentUIView {

    func createBackIcon() -> UIImageView {
        let iconSize: CGFloat = 15.0
        let imageView: UIImageView
        if #available(iOS 13.0, *) {
            let lightConfiguration = UIImage.SymbolConfiguration(pointSize: 5, weight: .light, scale: .small)
            imageView = UIImageView(image: UIImage(systemName: "arrow.backward", withConfiguration: lightConfiguration))
        } else {
            // Fallback on earlier versions
            var backArrowUIImage: UIImage? = UIImage()
            backArrowUIImage = backArrowUIImage!.resizeImage(image: UIImage(named: "backarrow", in: nil, compatibleWith: nil)!, targetSize: CGSize(width: iconSize, height: iconSize))!
            imageView = UIImageView(image: backArrowUIImage)
        }
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ConsentConstants.brandPurple
        imageView.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
        imageView.isUserInteractionEnabled = true
        let backButtonUITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backButtonClicked))
        imageView.addGestureRecognizer(backButtonUITapGestureRecognizer)
        
        return imageView
    }

    func createTitleLabel(width: CGFloat) -> UILabel {
        let titleHeight: CGFloat = 15.0
        let label = UILabel()
        label.text = "Ads by doceree"
        label.font = .systemFont(ofSize: ConsentConstants.fontSize12)
        label.textColor = ConsentConstants.brandPurple
        label.widthAnchor.constraint(equalToConstant: self.adViewFrame!.width).isActive = true
        label.heightAnchor.constraint(equalToConstant: titleHeight).isActive = true
        label.textAlignment = .center
        return label
    }
    
    func createHorizontalStack(_ icon: UIImageView, _ label: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        icon.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 5.0).isActive = true
        return stack
    }

    func createActionButton(title: String, iconName: String? = nil, action: Selector, iconOnRight: Bool = false) -> UIButton {
        guard let frame = adViewFrame else { return UIButton() }

        let btn = UIButton()
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(ConsentConstants.black, for: .normal)
        btn.backgroundColor = ConsentConstants.white
        btn.titleLabel?.font = .systemFont(ofSize: ConsentConstants.fontSize12)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        btn.widthAnchor.constraint(equalToConstant: isMediumRectangle ? frame.width * 0.8 : frame.width * 0.4).isActive = true
        btn.heightAnchor.constraint(equalToConstant: isMediumRectangle ? frame.height * 0.2 : frame.height / 2).isActive = true

        if let iconName = iconName, #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .light, scale: .small)
            let icon = UIImage(systemName: iconName, withConfiguration: config)?.withTintColor(ConsentConstants.brandPurple, renderingMode: .alwaysOriginal)
            btn.setImage(icon, for: .normal)
            btn.semanticContentAttribute = iconOnRight ? .forceRightToLeft : .forceLeftToRight
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        }

        return btn
    }
    
    func createButtonWithText(_ text: String, action: Selector) -> UIButton {
        let button = createButtonWithText(text)
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        button.addGestureRecognizer(tapGesture)
        return button
    }
    
    func createButtonWithText(_ text: String) -> UIButton {
        
        let buttonWidth: CGFloat = getButtonSizes().0
        let buttonHeight: CGFloat = getButtonSizes().1
        let buttonLabelFontSize: CGFloat = getButtonSizes().2
 
        let btnAdCoveringContent = UIButton()
        btnAdCoveringContent.setTitle(text, for: .normal)
        btnAdCoveringContent.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        btnAdCoveringContent.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        btnAdCoveringContent.setTitleColor(ConsentConstants.black, for: .normal)
        btnAdCoveringContent.backgroundColor = ConsentConstants.white
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
            let textFontSize: CGFloat = (self.isBanner || self.isSmallBanner) ? ConsentConstants.fontSize10 : ConsentConstants.fontSize12
            return (buttonWidth, buttonHeight, textFontSize)
        } else if formConsentType == .consentType3 {
            let buttonWidth: CGFloat = isMediumRectangle ? self.adViewFrame!.width * 0.8 : self.adViewFrame!.width * 0.4
            let buttonHeight: CGFloat = self.adViewFrame!.height * 0.9
            let textFontSize: CGFloat = (self.isBanner || self.isSmallBanner) ? ConsentConstants.fontSize8 : ConsentConstants.fontSize12
            return (buttonWidth, buttonHeight, textFontSize)
        }
        
        return (0, 0, 0)
    }
    
}
