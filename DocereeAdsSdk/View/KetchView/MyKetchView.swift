//
//  MyKetchView.swift
//  KetchSDK
//

import SwiftUI
import KetchSDK

// Example custom listener that simply logs all events
class MyKetchEventListener: KetchEventListener {
    func onLoad() {
        DocereeLog.debug("UI Loaded")
    }

    func onShow() {
        DocereeLog.debug("UI Shown")
    }

    func onDismiss() {
        DocereeLog.debug("UI Dismissed")
    }

    func onEnvironmentUpdated(environment: String?) {
        DocereeLog.debug("Environment Updated: \(String(describing: environment))")
    }

    func onRegionInfoUpdated(regionInfo: String?) {
        DocereeLog.debug("Region Info Updated: \(String(describing: regionInfo))")
    }

    func onJurisdictionUpdated(jurisdiction: String?) {
        DocereeLog.debug("Jurisdiction Updated: \(String(describing: jurisdiction))")
    }

    func onIdentitiesUpdated(identities: String?) {
        DocereeLog.debug("Identities Updated: \(String(describing: identities))")
    }

    func onConsentUpdated(consent: KetchSDK.ConsentStatus) {
        DocereeLog.debug("Consent Updated: \(consent)")
    }

    func onError(description: String) {
        DocereeLog.debug("Error: \(description)")
    }

    func onCCPAUpdated(ccpaString: String?) {
        DocereeLog.debug("CCPA String Updated: \(String(describing: ccpaString))")
    }

    func onTCFUpdated(tcfString: String?) {
        DocereeLog.debug("TCF String Updated: \(String(describing: tcfString))")
    }

    func onGPPUpdated(gppString: String?) {
        DocereeLog.debug("GPP String Updated: \(String(describing: gppString))")
    }
}

public struct MyKetchView: View {
    @ObservedObject var ketchUI: KetchUI
    
    // Define listener as a property of MyKetchView
    let listener = MyKetchEventListener()
    
    public init() {
        // Create the KetchSDK object
        let ketch = KetchSDK.create(
            organizationCode: "doceree",
            propertyCode: "ios",
            environmentCode: "production",
            identities: [
                Ketch.Identity(key: "idfa", value: getIdentifierForAdvertising() ?? "")
            ]
        )
        
        // Create the KetchUI object
        ketchUI = KetchUI(
            ketch: ketch,
            experienceOptions: [
                .forceExperience(.consent)
            ]
        )
        
        // Add our listener to the ketchUI class
        ketchUI.eventListener = listener
    }
    
    @State var selectedExperienceToShow: KetchUI.ExperienceOption.ExperienceToShow = .consent
    @State var selectedTab: KetchUI.ExperienceOption.PreferencesTab?
    @State var lang = "HI"
    @State var jurisdiction = "australia"
    @State var region = "AUS"
    @State var tabsExpanded = false
    @State var selectedTabs = KetchUI.ExperienceOption.PreferencesTab.allCases
    
    @ViewBuilder
    private func checkbox(_ value: Binding<Bool>) -> some View {
        Button {
            value.wrappedValue.toggle()
        } label: {
            Image(systemName: value.wrappedValue ? "circle.fill" : "circle")
        }
    }
    
    public var body: some View {
        ScrollView {
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Experience:")
                    Picker("Experience", selection: $selectedExperienceToShow) {
                        ForEach([KetchUI.ExperienceOption.ExperienceToShow.consent, .preferences], id: \.self) {
                            Text($0.name)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedExperienceToShow == .preferences {
                        Text("Tabs:")
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ]) {
                            ForEach(KetchUI.ExperienceOption.PreferencesTab.allCases, id: \.self) { tab in
                                prefTabCheckMarkView(tab: tab)
                            }
                        }
                        
//                        if !selectedTabs.isEmpty {
//                            HStack {
//                                Text("Active tab:")
//                                
//                                Picker("Active tab:", selection: $selectedTab) {
//                                    Text("none").tag(nil as KetchUI.ExperienceOption.PreferencesTab?)
//                                    
//                                    ForEach(selectedTabs, id: \.self) { tab in
//                                        Text(tab.rawValue.replacingOccurrences(of: "Tab", with: "")).tag(tab as KetchUI.ExperienceOption.PreferencesTab?)
//                                    }
//                                }
//                                .pickerStyle(.menu)
//                            }
//                        }
                    }
                    VStack {
                        HStack {
                            Text("Language:")
                            TextField("Language", text: $lang)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle()) // Styling
                        }

                        HStack {
                            Text("Jurisdiction:")
                            TextField("Jurisdiction", text: $jurisdiction)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle()) // Styling
                        }

                        HStack {
                            Text("Region:")
                            TextField("Region", text: $region)
                                .padding()
                                .textFieldStyle(RoundedBorderTextFieldStyle()) // Styling
                        }

                    }

                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button("Show") {
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
                            
                            ketchUI.reload(with: params.compactMap{$0})
                        }
                        .font(.system(.title))
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
//                    Button("Log local privacy strings") {
//                        showPrivacyStrings()
//                    }
                }
                .padding()
            }
        }
        .background(.white)
        .ketchView(model: $ketchUI.webPresentationItem)
    }
    
    private func showPrivacyStrings() {
        // fir some reson preview is not working when this strings are all in one array
        let keys = ["IABTCF_CmpSdkID",
                    "IABTCF_CmpSdkVersion",
                    "IABTCF_PolicyVersion",
                    "IABTCF_gdprApplies",
                    "IABTCF_PublisherCC",
                    "IABTCF_PurposeOneTreatment",
                    "IABTCF_UseNonStandardTexts",
                    "IABTCF_TCString",
                    "IABTCF_VendorConsents"]
        
        let keys2 = ["IABTCF_VendorLegitimateInterests",
                     "IABTCF_PurposeConsents",
                     "IABTCF_PurposeLegitimateInterests",
                     "IABTCF_SpecialFeaturesOptIns",
                     "IABTCF_PublisherConsent",
                     "IABTCF_PublisherLegitimateInterests",
                     "IABTCF_PublisherCustomPurposesConsents",
                     "IABTCF_PublisherCustomPurposesLegitimateInterests",
                     "IABUSPrivacy_String"]
        
        let keys3 = ["IABGPP_HDR_Version",
                     "IABGPP_HDR_Sections",
                     "IABGPP_HDR_GppString",
                     "IABGPP_GppSID",
                     "IABGPP_tcfeuv2_GppSID"]
        
        DocereeLog.debug("\n* ----- Begin privacy strings ---- *")
        (keys + keys2 + keys3).forEach {
            DocereeLog.debug("\($0): \(UserDefaults.standard.value(forKey: $0) ?? "")")
        }
        DocereeLog.debug("* ----- End privacy strings ---- *\n")
    }
    
    private func prefTabCheckMarkView(tab: KetchUI.ExperienceOption.PreferencesTab) -> some View {
        HStack {
            Image(systemName: selectedTabs.contains(tab) ? "checkmark.square" : "square")
            Spacer()
            Text(tab.rawValue.replacingOccurrences(of: "Tab", with: ""))
        }
        .padding(2)
        .background(.gray.opacity(0.2))
        .cornerRadius(3)
        .onTapGesture {
            if let index = selectedTabs.firstIndex(of: tab) {
                selectedTabs.remove(at: index)
            } else {
                selectedTabs.append(tab)
            }
        }
    }
}

extension KetchUI.ExperienceOption.ExperienceToShow {
    var name: String {
        switch self {
        case .consent:
            return "Consent"
        case .preferences:
            return "Preferences"
        }
    }
}

//#Preview {
//    MyKetchView()
//}
