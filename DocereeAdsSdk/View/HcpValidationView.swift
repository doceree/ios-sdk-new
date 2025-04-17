//
//  HcpValidationView.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 01/04/24.
//

import UIKit

public class HcpValidationView: UIView  {
    
    // MARK: - Properties
    var hcpResponseData: HcpValidation?
    var containerView: UIView!
    var hcpValidationRequest: HcpValidationRequest?
    public var delegate: HcpValidationViewDelegate?
    private var downloadedFont: UIFont? // ✅ Store the font globally once downloaded

    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Setup View
    private func setupView() {

        backgroundColor = UIColor(white: 0, alpha: 0.6) // Semi-transparent background
        
        // Create the main popup container
        let popupContainer = UIView()
        popupContainer.backgroundColor = .white
        popupContainer.layer.cornerRadius = 12
        popupContainer.clipsToBounds = true
        addSubview(popupContainer)
        
        popupContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            popupContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            popupContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            popupContainer.widthAnchor.constraint(equalTo: widthAnchor, multiplier: isLargeScreen() ?  0.85 : 0.90)
        ])
        // Get template ID and configure the UI accordingly
        guard let templateId = hcpResponseData?.data.templateId else {
            print("Unknown templateId")
            return
        }
        configureTemplate(in: popupContainer, templateId: templateId)
    }

    // MARK: - Templates
    private func configureTemplate(in container: UIView, templateId: Int) {
        
        let titleLabel = createTitleLabel()
        let closeButton = createCloseButton()
        let titleStack = createTitleStackView(titleLabel: titleLabel, closeButton: closeButton)
        container.addSubview(titleStack)
        NSLayoutConstraint.activate([
            titleStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        let descriptionLabel = createDescriptionLabel()
        container.addSubview(descriptionLabel)

        applyFontsSequentially(to: titleLabel, descriptionLabel: descriptionLabel)
        
        var buttonTopConstraint: NSLayoutConstraint?
        var buttonLeftConstraint: NSLayoutConstraint?
        
        let buttonStack = createButtonStack()
        container.addSubview(buttonStack)

        if templateId == 2 || templateId == 3 {
            let iconImageView = createIconImageView(templateId: templateId)
            container.addSubview(iconImageView)
            
            NSLayoutConstraint.activate([
                iconImageView.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 10),
                iconImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
                iconImageView.widthAnchor.constraint(equalToConstant: templateId == 2 ? 100 : 140)
            ])

            
            NSLayoutConstraint.activate([
                descriptionLabel.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 10),
                descriptionLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
                descriptionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10)
            ])

            // ✅ Buttons should be to the left of the icon and aligned to the bottom
//            let leading: CGFloat = isLargeScreen() ? 100 : 0
            buttonTopConstraint = buttonStack.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10)
            buttonLeftConstraint = buttonStack.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor, constant: 0)

            
        } else {
            NSLayoutConstraint.activate([
                descriptionLabel.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 10),
                descriptionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                descriptionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
            ])
            
            buttonTopConstraint = buttonStack.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10)
            buttonLeftConstraint = buttonStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16)

        }

        NSLayoutConstraint.activate([
            buttonTopConstraint!,
            buttonLeftConstraint!,
            buttonStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: isLargeScreen() ? 40 : 30)
        ])
    }

    // MARK: - Create UI Components
    private func createTitleLabel() -> UILabel {
        let titleLabel = UILabel()
        titleLabel.text = Popup.title
        titleLabel.textColor = UIColor(hexString: hcpResponseData?.data.fontColour ?? "000000")
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }
    
    private func createCloseButton() -> UIImageView {
        let closeButton: UIImageView
        
        if #available(iOS 13.0, *) {
            closeButton = UIImageView(image: UIImage(systemName: "xmark"))
        } else {
            closeButton = UIImageView(image: UIImage(named: "close_icon")) // Provide a custom image for older iOS
        }
        
        closeButton.tintColor = .black
        closeButton.isUserInteractionEnabled = true
        closeButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeButtonTapped)))
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return closeButton
    }
    
    private func createTitleStackView(titleLabel: UILabel, closeButton: UIImageView) -> UIStackView {
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, closeButton])
        titleStack.axis = .horizontal
        titleStack.spacing = 8
        titleStack.alignment = .fill
        titleStack.distribution = .fillProportionally
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        return titleStack
    }
    
    private func createDescriptionStackView(descriptionLabel: UILabel, iconImageView: UIImageView?) -> UIStackView {
        if let iconImageView {
            let descriptionStack = UIStackView(arrangedSubviews: [iconImageView, descriptionLabel])
            descriptionStack.axis = .horizontal
            descriptionStack.spacing = 8
            descriptionStack.alignment = .top
            descriptionStack.translatesAutoresizingMaskIntoConstraints = false
            return descriptionStack
        } else {
            let descriptionStack = UIStackView(arrangedSubviews: [descriptionLabel])
            descriptionStack.axis = .horizontal
            descriptionStack.spacing = 8
            descriptionStack.alignment = .top
            descriptionStack.translatesAutoresizingMaskIntoConstraints = false
            return descriptionStack
        }
    }
    
    private func createDescriptionLabel() -> UILabel {
            let label = UILabel()
            label.text = Popup.description
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = UIColor(hexString: hcpResponseData?.data.fontColour ?? "000000")
            label.textAlignment = .left
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }
        
        private func createIconImageView(templateId: Int) -> UIImageView {
            let iconImageView = UIImageView()
            let imageName = templateId == 2 ? "doc1" : "doc2"
            if let bundleURL = Bundle(for: HcpValidationView.self).url(forResource: "DocereeAdsSdk", withExtension: "bundle"),
               let bundle = Bundle(url: bundleURL) {
                iconImageView.image = UIImage(named: imageName, in: bundle, compatibleWith: nil)
            }
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iconImageView.widthAnchor.constraint(equalToConstant: 100),
                iconImageView.heightAnchor.constraint(equalToConstant: 100)
            ])
            return iconImageView
        }
        
        private func createButtonStack() -> UIStackView {
            let rejectButton = createButton(title: Popup.noButtonText, backgroundColor: .white, textColor: .black, borderWidth: 1.0, buttonId: "cookie-decline-btn")
            let acceptButton = createButton(title: Popup.yesButtonText, backgroundColor: UIColor(hexString: "4778ef"), textColor: .white, borderWidth: 0.0, buttonId: "cookie-accept-btn")
            
            let buttonStack = UIStackView(arrangedSubviews: [rejectButton, acceptButton])
            buttonStack.axis = .horizontal
            buttonStack.spacing = isLargeScreen() ? 12 : 8
            buttonStack.alignment = .fill
            buttonStack.distribution = .fillProportionally
            buttonStack.translatesAutoresizingMaskIntoConstraints = false
            return buttonStack
        }

    private func createButton(title: String, backgroundColor: UIColor, textColor: UIColor, borderWidth: CGFloat , buttonId: String) -> UIButton {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(textColor, for: .normal)
            button.backgroundColor = backgroundColor
            button.layer.cornerRadius = 10
            button.accessibilityIdentifier = buttonId  // ✅ Assign Button ID
            button.layer.borderWidth = borderWidth
            button.layer.borderColor = UIColor(hexString: "888888").cgColor
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: isLargeScreen() ? 18 : 12, weight: .medium)
            return button
        }
    

}

// MARK: - Button Actions
extension HcpValidationView {

    /// ✅ **Handles All Button Clicks and Calls `onClickButton` with Button ID**
    @objc private func buttonTapped(_ sender: UIButton) {
        guard let buttonId = sender.accessibilityIdentifier else { return }
        onClickButton(buttonId: buttonId)
    }
    
    @objc private func closeButtonTapped() {
        removeView()
        onClickButton(buttonId: "")
    }
    
    func onClickButton(buttonId: String) {
        print("Button clicked with ID: \(buttonId)")
        var duration: TimeInterval
        var action: PopupAction
        var actionUrl: String?
        switch(buttonId) {
        case "cookie-accept-btn":
            duration = ExpirationDuration.year1
            action = .accept
            actionUrl = hcpResponseData?.data.acceptUrl ?? ""
        case "cookie-decline-btn":
            duration = ExpirationDuration.days15
            action = .reject
            actionUrl = hcpResponseData?.data.closeUrl ?? ""
        default:
            duration = ExpirationDuration.hours6
            action = .close
        }
        
        if actionUrl != nil {
            self.delegate?.hcpPopupAction(action, actionUrl!)
        }
        saveTimeInterval(duration: duration)
        updateHcpValidaiton(hcpStatus: action.rawValue)
        removeView()
    }
}

// MARK: - Networking & Data Handling
extension HcpValidationView {
    func isHcpExist() -> Bool {
        guard let loggedInUser = DocereeMobileAds.shared().getProfile() else {
            print("Error: Not found profile data")
            return false
        }
        return (loggedInUser.specialization != nil) || (loggedInUser.hcpId != nil)
    }
    
    func removeView() {
        self.removeFromSuperview()
        self.delegate = nil
    }
    
    public func loadData(hcpValidationRequest: HcpValidationRequest) {
        if isHcpExist() {
            removeView()
            return
        }
        
        self.hcpValidationRequest = hcpValidationRequest
        
        if (!getInterval()) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.removeView()
            }
            return
        }
        
        hcpValidationRequest.getHcpSelfValidation() { (results) in
            if let result = results.data {
                do {
                    self.hcpResponseData = try JSONDecoder().decode(HcpValidation.self, from: result)
                    guard (self.hcpResponseData?.data) != nil else { return }
                    DispatchQueue.main.async {
                        if self.hcpResponseData?.code == 200 && self.hcpResponseData?.data.valStatus == 0 && self.hcpResponseData?.data.templateId != 0 {
                            if self.isHcpExist() {
                                self.removeView()
                                return
                            }
                            self.delegate?.hcpValidationViewSuccess(self)
                            self.setupView()
                        }
                        else {
                            self.delegate?.hcpValidationView(self, didFailToReceiveHcpWithError: HcpRequestError.noScriptFound)
                            DispatchQueue.main.async {
                                self.removeView()
                            }
                        }
                    }
                } catch {
                    self.delegate?.hcpValidationView(self, didFailToReceiveHcpWithError: HcpRequestError.parsingError)
                    DispatchQueue.main.async {
                        self.removeView()
                    }
                }
                
            } else {
                DispatchQueue.main.async {
                    self.removeView()
                }
            }
        }
    }
    
    private func getInterval() -> Bool {
        let manager = UserDefaultsManager.shared
        return manager.getUserDefaults() == nil
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
        removeView()
    }

    internal func updateHcpValidaiton(hcpStatus: String) {
        hcpValidationRequest?.updateHcpSelfValidation(hcpStatus)
    }

//    func getInterval() -> Bool {
//        let manager = UserDefaultsManager.shared
//        manager.expirationDuration = ExpirationDuration.minutes10
//        // Retrieve user defaults
//        if let userData = manager.getUserDefaults() {
//            print("User defaults exist for :", userData)
//            return false
//        } else {
//            print("User defaults expired or not set.")
//            return true
//        }
//    }
}

extension HcpValidationView {

    private func loadFontIfNeeded(completion: @escaping (UIFont?) -> Void) {
        if let font = downloadedFont {
            completion(font) // ✅ Use cached font
        } else {
            let fontName = hcpResponseData?.data.font ?? "Helvetica"
            let googleFontURL = "https://fonts.googleapis.com/css2?family=\(fontName):wght@400;700"

            GoogleFontLoader.loadFont(fontName: fontName, googleFontURL: googleFontURL, fontSize: 15.0) { font in
                if let font = font {
                    self.downloadedFont = font // ✅ Store it for reuse
                }
                completion(font)
            }
        }
    }
    
    private func applyFontsSequentially(to titleLabel: UILabel, descriptionLabel: UILabel) {
        loadFontIfNeeded { font in
            guard let font = font else {
                print("❌ Font loading failed for title label")
                return
            }
            titleLabel.font = font.withSize(isLargeScreen() ? 20 : 15)

            // ✅ Once title font is set, apply the same font to description
            descriptionLabel.font = font.withSize(isLargeScreen() ? 16 : 12)
        }
    }
}
