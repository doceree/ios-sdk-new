import UIKit
import KetchSDK


// MARK: - MyKetchUIKitEventListener
extension CreateCMPView: KetchEventListener {
    public func onShow() {
        print("UI Shown")
        
        guard let viewController = ketchUI.webPresentationItem?.viewController,
              let parentVC = self.parentViewController else {
            return
        }

        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalTransitionStyle = .crossDissolve
        parentVC.present(viewController, animated: true)
    }

    public func onDismiss() {
        print("UI Dismissed")
        parentViewController?.dismiss(animated: true)
    }

    public func onEnvironmentUpdated(environment: String?) {
        print("Environment Updated: \(String(describing: environment))")
    }

    public func onRegionInfoUpdated(regionInfo: String?) {
        print("Region Info Updated: \(String(describing: regionInfo))")
    }

    public func onJurisdictionUpdated(jurisdiction: String?) {
        print("Jurisdiction Updated: \(String(describing: jurisdiction))")
    }

    public func onIdentitiesUpdated(identities: String?) {
        print("Identities Updated: \(String(describing: identities))")
    }

    public func onConsentUpdated(consent: KetchSDK.ConsentStatus) {
        print("Consent Updated: \(consent)")
    }

    public func onError(description: String) {
        print("Error: \(description)")
    }

    public func onCCPAUpdated(ccpaString: String?) {
        print("CCPA String Updated: \(String(describing: ccpaString))")
    }

    public func onTCFUpdated(tcfString: String?) {
        print("TCF String Updated: \(String(describing: tcfString))")
    }

    public func onGPPUpdated(gppString: String?) {
        print("GPP String Updated: \(String(describing: gppString))")
    }
}


// MARK: - MyKetchView
public class CreateCMPView: UIView {
    private var ketchUI: KetchUI
    private var selectedExperienceToShow: KetchUI.ExperienceOption.ExperienceToShow = .consent
    private var selectedTab: KetchUI.ExperienceOption.PreferencesTab?
    private var lang = "HI"
    private var jurisdiction = "australia"
    private var region = "AUS"
    private var selectedTabs = KetchUI.ExperienceOption.PreferencesTab.allCases

    public init() {
        // Initialize KetchSDK
        let ketch = KetchSDK.create(
            organizationCode: "doceree",
            propertyCode: "ios",
            environmentCode: "production",
            identities: [
                Ketch.Identity(key: "idfa", value: getIdentifierForAdvertising() ?? "")
            ]
        )

        // Initialize KetchUI
        self.ketchUI = KetchUI(
            ketch: ketch,
            experienceOptions: [
                .forceExperience(.consent)
            ]
        )

        super.init(frame: .zero)

        // Set listener
        ketchUI.eventListener = self

        // Load Ketch view
        loadKetchView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadKetchView() {
        var params: [KetchUI.ExperienceOption?] = [
            .region(code: region),
            .language(code: lang),
            .forceExperience(selectedExperienceToShow),
            .jurisdiction(code: jurisdiction)
        ]

        if !selectedTabs.isEmpty && selectedExperienceToShow == .preferences {
            let selectedTabsNames = selectedTabs.compactMap { $0.rawValue }
            params.append(.preferencesTabs(selectedTabsNames.joined(separator: ",")))

            if let selectedTab, selectedTabs.contains(selectedTab) {
                params.append(.preferencesTab(selectedTab))
            }
        }

        ketchUI.reload(with: params.compactMap { $0 })
    }
}
