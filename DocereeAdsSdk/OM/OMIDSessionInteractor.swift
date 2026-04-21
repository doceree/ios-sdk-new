//
//  OMIDHelper.swift
//  OM-TestApp
//
//  Created by Michele Simone on 14/11/2022.
//  Copyright © 2022 IAB Techlab. All rights reserved.
//

import Foundation
import UIKit

#if canImport(OMSDK_Doceree)
import OMSDK_Doceree
#endif

#if !os(tvOS)
import WebKit
#endif


/// Utility wrapper around the OMID SDK, for demo purpose only.
/// Not to be used in a production integration
class OMIDSessionInteractor {

    private var adEvents: OMIDDocereeAdEvents?
    private var mediaEvents: OMIDDocereeMediaEvents?
    private let adUnit: AdUnit
    private let adView: UIView?
    #if !os(tvOS)
    private let webViewContext: WKWebView?
    #endif

    private let adSession: OMIDDocereeAdSession?

    /// Uniquely identify your integration.
    private static let omidPartner: OMIDDocereePartner? = {
        // The IAB Tech Lab will assign a unique partner name to you at the time of integration.
        let partnerName = "doceree"
        // For an ads SDK, this should be the same as your SDK’s semantic version. For an app publisher, this should be the same as your app version.
        let partnerVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        if let partner = OMIDDocereePartner(name: partnerName, versionString: partnerVersion ?? "1.0") {
            return partner
        }
        DocereeLog.debug("Unable to initialize OMID partner with CFBundleVersion, falling back to 1.0")
        return OMIDDocereePartner(name: partnerName, versionString: "1.0")
    }()

#if os(tvOS)
// The only substantial difference between iOS and tvOS is the lack of WebKit in the latter
// for this on tvOS the OMID utility object doesn't have the option to use a web view to host the
// creative or to run the context. Once the OMID session has been created all the other
// functionalities stays the same.


    /// Creates an OMID Utility object
    /// - Parameters:
    ///   - adUnit: The type of ad
    ///   - adView: The ad view
    init?(adUnit: AdUnit, adView: UIView? = nil) {
        self.adUnit = adUnit
        self.adView = adView
        self.adSession = OMIDSessionInteractor.createAdSession(adUnit: adUnit, adView: adView)
        guard self.adSession != nil else { return nil }
    }

    private static func createAdSession(adUnit: AdUnit, adView: UIView?) -> OMIDDocereeAdSession? {
        guard let omidPartner = Self.omidPartner else {
            DocereeLog.debug("OMID partner not available")
            return nil
        }
        // ensure OMID has been already activated
        guard OMIDDocereeSDK.shared.isActive else {
            DocereeLog.debug("OMID is not active")
            return nil
        }

        // Obtain ad session context. The context may be different depending on the type of the ad unit.
        guard let context = createAdSessionContext(withPartner: omidPartner, adUnit: adUnit, adView: adView) else {
            return nil
        }

        // Obtain ad session configuration. Configuration may be different depending on the type of the ad unit.
        guard let configuration = createAdSessionConfiguration(adUnit: adUnit) else {
            return nil
        }

        do {
            // Create ad session
            let session = try OMIDDocereeAdSession(configuration: configuration, adSessionContext: context)

            DocereeLog.debug("Session created for \(adUnit.title)")
            // Only add adView if not nativeAudio adUnit
            if adUnit == .nativeAudio {
                return session
            }

            // Provide main ad view for measurement
            guard let adView = adView else {
                DocereeLog.debug("Ad View is not initialized")
                return nil
            }
            session.mainAdView = adView
            return session
        } catch {
            DocereeLog.debug("Unable to instantiate ad session: \(error)")
            return nil
        }

    }

    private static func createAdSessionContext(withPartner partner: OMIDDocereePartner, adUnit: AdUnit, adView: UIView?) -> OMIDDocereeAdSessionContext? {
        do {
            switch adUnit {
            case .HTMLDisplay, .HTMLVideo, .JSDisplay, .JSVideo:
                DocereeLog.debug("OMID ad unit \(adUnit.title) not supported on tvOS")
                return nil
            case .nativeDisplay, .nativeVideo, .nativeAudio:
                //These values should be parsed from the ad response
                //For example:
                //[
                //  {
                //      "vendorKey": "iabtechlab.com-omid",
                //      "javascriptResourceUrl": "https://server.com/creative/omid-validation-verification-script-v1.js",
                //      "verificationParameters": "parameterstring"
                //  },
                //]


                //Ad Verification
                //These values should be parsed from the VAST document

                //In this example we don't parse VAST, but if we did, the <AdVerifications> node would look like this:
                //<AdVerifications>
                //  <Verification vendor="iabtechlab.com-omid">
                //      <JavaScriptResource apiFramework="omid" browserOptional=”true”>
                //          <![CDATA[https://server.com/omid-validation-verification-script-v1.js]]>
                //      </JavaScriptResource>
                //      <VerificationParameters>
                //          <![CDATA[parameterstring]]>
                //      </VerificationParameters>
                //  </Verification>
                //</AdVerifications>



                // Using validation verification script as an example
                let urlToMeasurementScript = Constants.verificationScriptURL

                // Vendor key
                let vendorKey = Constants.vendorKey

                // Verification Parameters. This is just an arbitrary string, however with validation
                // verification script, the value that is passed here will be used as a remote URL for tracking events
                let parameters = Constants.verificationParameters

                // Create verification resource using the values provided in the ad response
                guard let verificationResource = createVerificationScriptResource(vendorKey: vendorKey,
                                                                                  verificationScriptURL: urlToMeasurementScript,
                                                                                  parameters: parameters)
                else {
                    DocereeLog.debug("Unable to instantiate session context: verification resource cannot be created")
                    return nil
                }


                return try OMIDDocereeAdSessionContext(partner: partner,
                                                script: omidJSService,
                                                resources: [verificationResource],
                                                contentUrl: nil,
                                                customReferenceIdentifier: nil)
            }
        } catch {
            DocereeLog.debug("Unable to create ad session context: \(error)")
            return nil
        }
    }


#else

    /// Creates an OMID Utility object for an HTML ad
    /// - Parameters:
    ///   - adUnit: The type of ad
    ///   - webCreative: The webView where the ad creative and the OMID context is running
    convenience init?(adUnit: AdUnit, webCreative: WKWebView) {
        self.init(adUnit: adUnit, adView: webCreative, webViewContext: webCreative)
    }

    /// Creates an OMID Utility object
    /// - Parameters:
    ///   - adUnit: The type of ad
    ///   - adView: The ad view
    ///   - webViewContext: The webView where the OMID Context is running if not managed natively.
    init?(adUnit: AdUnit, adView: UIView? = nil, webViewContext: WKWebView? = nil) {
        self.adUnit = adUnit
        self.adView = adView
        self.webViewContext = webViewContext
        self.adSession = OMIDSessionInteractor.createAdSession(adUnit: adUnit, adView: adView, omidJSContext: webViewContext)
        guard self.adSession != nil else { return nil }
    }

    private static func createAdSession(adUnit: AdUnit, adView: UIView?, omidJSContext: WKWebView?) -> OMIDDocereeAdSession? {
        guard let omidPartner = Self.omidPartner else {
            DocereeLog.debug("OMID partner not available")
            return nil
        }
        // ensure OMID has been already activated
        guard OMIDDocereeSDK.shared.isActive else {
            DocereeLog.debug("OMID is not active")
            return nil
        }

        // Obtain ad session context. The context may be different depending on the type of the ad unit.
        guard let context = createAdSessionContext(withPartner: omidPartner, adUnit: adUnit, adView: adView,  omidJSContext: omidJSContext) else {
            return nil
        }

        // Obtain ad session configuration. Configuration may be different depending on the type of the ad unit.
        guard let configuration = createAdSessionConfiguration(adUnit: adUnit) else {
            return nil
        }

        do {
            // Create ad session
            let session = try OMIDDocereeAdSession(configuration: configuration, adSessionContext: context)

            DocereeLog.debug("Session created for \(adUnit.title)")
            // Only add adView if not nativeAudio adUnit
            if adUnit == .nativeAudio {
                return session
            }

            // Provide main ad view for measurement
            guard let adView = adView else {
                DocereeLog.debug("Ad View is not initialized")
                return nil
            }
            session.mainAdView = adView
            return session
        } catch {
            DocereeLog.debug("Unable to instantiate ad session: \(error)")
            return nil
        }

    }

    private static func createAdSessionContext(withPartner partner: OMIDDocereePartner, adUnit: AdUnit, adView: UIView?, omidJSContext: WKWebView?) -> OMIDDocereeAdSessionContext? {
        do {
            switch adUnit {
            case .HTMLDisplay, .HTMLVideo:
                guard let webView = omidJSContext else {
                    DocereeLog.debug("Unable to create ad session context: webView is not initialized")
                    return nil
                }
                return try OMIDDocereeAdSessionContext(partner: partner,
                                                webView: webView,
                                                contentUrl: nil,
                                                customReferenceIdentifier: nil)
            case .JSDisplay, .JSVideo:
                guard let webView = omidJSContext else {
                    DocereeLog.debug("Unable to create ad session context: webView is not initialized")
                    return nil
                }
                return try OMIDDocereeAdSessionContext(partner: partner, javaScriptWebView: webView, contentUrl: nil, customReferenceIdentifier: nil)

            case .nativeDisplay, .nativeVideo, .nativeAudio:
                //These values should be parsed from the ad response
                //For example:
                //[
                //  {
                //      "vendorKey": "iabtechlab.com-omid",
                //      "javascriptResourceUrl": "https://server.com/creative/omid-validation-verification-script-v1.js",
                //      "verificationParameters": "parameterstring"
                //  },
                //]


                //Ad Verification
                //These values should be parsed from the VAST document

                //In this example we don't parse VAST, but if we did, the <AdVerifications> node would look like this:
                //<AdVerifications>
                //  <Verification vendor="iabtechlab.com-omid">
                //      <JavaScriptResource apiFramework="omid" browserOptional=”true”>
                //          <![CDATA[https://server.com/omid-validation-verification-script-v1.js]]>
                //      </JavaScriptResource>
                //      <VerificationParameters>
                //          <![CDATA[parameterstring]]>
                //      </VerificationParameters>
                //  </Verification>
                //</AdVerifications>



                // Using validation verification script as an example
                let urlToMeasurementScript = Constants.verificationScriptURL

                // Vendor key
                let vendorKey = Constants.vendorKey

                // Verification Parameters. This is just an arbitrary string, however with validation
                // verification script, the value that is passed here will be used as a remote URL for tracking events
                let parameters = Constants.verificationParameters

                // Create verification resource using the values provided in the ad response
                guard let verificationResource = createVerificationScriptResource(vendorKey: vendorKey,
                                                                                  verificationScriptURL: urlToMeasurementScript,
                                                                                  parameters: parameters)
                else {
                    DocereeLog.debug("Unable to instantiate session context: verification resource cannot be created")
                    return nil
                }


                return try OMIDDocereeAdSessionContext(partner: partner,
                                                script: omidJSService,
                                                resources: [verificationResource],
                                                contentUrl: nil,
                                                customReferenceIdentifier: nil)
            }
        } catch {
            DocereeLog.debug("Unable to create ad session context: \(error)")
            return nil
        }

    }
    #endif



    private static func createAdSessionConfiguration(adUnit: AdUnit) -> OMIDDocereeAdSessionConfiguration? {
        do {
            switch adUnit {
            case .HTMLDisplay:
                return try OMIDDocereeAdSessionConfiguration(creativeType: .htmlDisplay,
                                                      impressionType: .beginToRender,
                                                      impressionOwner: .javaScriptOwner,
                                                      mediaEventsOwner: .noneOwner,
                                                      isolateVerificationScripts: false)
            case .HTMLVideo:
                return try OMIDDocereeAdSessionConfiguration(creativeType: .video,
                                                      impressionType: .beginToRender,
                                                      impressionOwner: .javaScriptOwner,
                                                      mediaEventsOwner: .javaScriptOwner,
                                                      isolateVerificationScripts: false)
            case .nativeDisplay, .JSDisplay:
                return try OMIDDocereeAdSessionConfiguration(creativeType: .nativeDisplay,
                                                      impressionType: .viewable,
                                                      impressionOwner: .nativeOwner,
                                                      mediaEventsOwner: .noneOwner,
                                                      isolateVerificationScripts: true)
            case .nativeVideo, .JSVideo:
                return try OMIDDocereeAdSessionConfiguration(creativeType: .video,
                                                      impressionType: .beginToRender,
                                                      impressionOwner: .nativeOwner,
                                                      mediaEventsOwner: .nativeOwner,
                                                      isolateVerificationScripts: false)
            case .nativeAudio:
                return try OMIDDocereeAdSessionConfiguration(creativeType: .audio,
                                                      impressionType: .audible,
                                                      impressionOwner: .nativeOwner,
                                                      mediaEventsOwner: .nativeOwner,
                                                      isolateVerificationScripts: false)
            }
        } catch {
            DocereeLog.debug("Unable to create ad session configuration: \(error)")
            return nil
        }
    }

    private func createAdEventsPublisher() {
        guard let adSession else { return }
        // Create event publisher before starting the session
        do {
            self.adEvents = try OMIDDocereeAdEvents(adSession: adSession)
        } catch {
            DocereeLog.debug("Unable to instantiate OMIDAdEvents: \(error)")
        }
    }

    private func createMediaEventsPublisher() {
        guard let adSession else { return }
        if adUnit.generatesNativeMediaEvents {
            do {
                self.mediaEvents = try OMIDDocereeMediaEvents(adSession: adSession)
            } catch {
                DocereeLog.debug("Unable to instantiate OMIDMediaEvents: \(error)")
            }
        }
    }


    /// Create a resource representing a verification script to be loaded in the OMID session
    /// - Parameters:
    ///   - vendorKey: Vendor identifier
    ///   - verificationScriptURL: script location
    ///   - parameters: Any parameter to be passed to the verification script.
    /// - Returns: verification script resource to be used in session creation
    private static func createVerificationScriptResource(vendorKey: String?, verificationScriptURL: String, parameters: String?) -> OMIDDocereeVerificationScriptResource? {
        guard let URL = URL(string: verificationScriptURL) else {
            DocereeLog.debug("Unable to parse Verification Script URL: \(verificationScriptURL)")
            return nil
        }

        if let vendorKey = vendorKey,
           let parameters = parameters,
           vendorKey.count > 0 && parameters.count > 0 {
            return OMIDDocereeVerificationScriptResource(url: URL,
                                                  vendorKey: vendorKey,
                                                  parameters: parameters)
        } else {
            return OMIDDocereeVerificationScriptResource(url: URL)
        }
    }
}

// MARK: Utility interface

extension OMIDSessionInteractor {

    func startSession() {
        guard let adSession else {
            DocereeLog.debug("OMID session unavailable; startSession skipped for \(adUnit.title)")
            return
        }
        DocereeLog.debug("Starting session for \(adSession.debugDescription), \(adUnit.title)")

        createAdEventsPublisher()
        createMediaEventsPublisher()

        adSession.start()
    }

    func addCloseButtonObstruction(_ button: UIView) {
        guard let adSession else {
            DocereeLog.debug("OMID session unavailable; addCloseButtonObstruction skipped")
            return
        }
        DocereeLog.debug("Adding close button obstruction for \(adUnit.title)")
        do {
            try adSession.addFriendlyObstruction(button,
                                                 purpose: .closeAd,
                                                 detailedReason: "Close Ad Button")
        } catch {
            DocereeLog.debug("Unable to add friendly obstruction \(error.localizedDescription)")
        }
    }

    func fireAdLoaded() {
        DocereeLog.debug("Firing ad loaded \(adUnit.title)")
        guard let adEvents = self.adEvents else {
            DocereeLog.debug("OMID ad events not available; loaded event skipped")
            return
        }
        do {
            try adEvents.loaded()
        } catch {
            DocereeLog.debug("OMID load error: \(error.localizedDescription)")
        }
    }

    func fireAdLoaded(vastProperties: OMIDDocereeVASTProperties) {
        DocereeLog.debug("Firing ad loaded \(adUnit.title)")
        guard let adEvents = self.adEvents else {
            DocereeLog.debug("OMID ad events not available; loaded(VAST) event skipped")
            return
        }
        do {
            try adEvents.loaded(with: vastProperties)
        } catch {
            DocereeLog.debug("OMID load error: \(error.localizedDescription)")
        }
    }

    func fireImpression() {
        DocereeLog.debug("Firing impression for  \(adUnit.title)")
        guard let adEvents = self.adEvents else {
            DocereeLog.debug("OMID ad events not available; impression skipped")
            return
        }
        do {
            try adEvents.impressionOccurred()
        } catch {
            DocereeLog.debug("OMID impression error: \(error.localizedDescription)")
        }
    }

    func stopSession() {
        DocereeLog.debug("Stopping the session \(adUnit.title)")
        adSession?.finish()
    }

    func getMediaEventsPublisher() -> OMIDDocereeMediaEvents? {
        guard let mediaEvents = self.mediaEvents else {
            DocereeLog.debug("OMIDMediaEvents not instantiated; start the session first")
            return nil
        }

        return mediaEvents
    }

    func getAdEventsPublisher() -> OMIDDocereeAdEvents? {
        guard let adEvents = self.adEvents else {
            DocereeLog.debug("OMIDAdEvents not instantiated; start the session first")
            return nil
        }
        return adEvents
    }

    /// The OMID SDK should be activated early on the application lifecycle
    /// - Returns: true if successful
    @discardableResult static func activateOMSDK() -> Bool {
        if OMIDDocereeSDK.shared.isActive {
            return true
        }

        // Activate the SDK
        OMIDDocereeSDK.shared.activate()

        return OMIDDocereeSDK.shared.isActive
    }

    //    For the simplicity of the demo project the javascript OMID SDK is embedded in the application bundle
    //    in a real life scenario the javascript file should be hosted in a remote server
    static func prefetchOMIDSDK() {
        DocereeLog.debug("Simulating OMID SDK Javascript download ...")
    }

//    static var omidJSService: String {
//        let omidServiceUrl = Bundle.main.url(forResource: "omsdk-v1", withExtension: "js")!
//        return try! String(contentsOf: omidServiceUrl)
//    }
    
    static var omidJSService: String {
        guard let bundleURL = Bundle(for: HcpValidationView.self).url(forResource: "DocereeAdsSdk", withExtension: "bundle"),
              let bundle = Bundle(url: bundleURL),
              let omidServiceUrl = bundle.url(forResource: "omsdk-v1", withExtension: "js") else {
            DocereeLog.debug("Could not locate omsdk-v1.js in DocereeAdsSdk.bundle")
            return ""
        }

        do {
            return try String(contentsOf: omidServiceUrl)
        } catch {
            DocereeLog.debug("Failed to load contents of omsdk-v1.js: \(error)")
            return ""
        }
    }

    
}
