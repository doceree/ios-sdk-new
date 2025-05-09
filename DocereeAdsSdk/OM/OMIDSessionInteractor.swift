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

    private let adSession: OMIDDocereeAdSession

    /// Uniquely identify your integration.
    private static var partner: OMIDDocereePartner = {
        // The IAB Tech Lab will assign a unique partner name to you at the time of integration.
        let partnerName = "doceree"
        // For an ads SDK, this should be the same as your SDK’s semantic version. For an app publisher, this should be the same as your app version.
        let partnerVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        guard let partner = OMIDDocereePartner(name: partnerName, versionString: partnerVersion ?? "1.0") else {
            fatalError("Unable to initialize OMID partner")
        }

        return partner
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
    init(adUnit: AdUnit, adView: UIView? = nil) {
        self.adUnit = adUnit
        self.adView = adView
        self.adSession = OMIDSessionInteractor.createAdSession(adUnit: adUnit, adView: adView)
    }

    private static func createAdSession(adUnit: AdUnit, adView: UIView?) -> OMIDDocereeAdSession {
        // ensure OMID has been already activated
        guard OMIDDocereeSDK.shared.isActive else {
            fatalError("OMID is not active")
        }

        // Obtain ad session context. The context may be different depending on the type of the ad unit.
        let context = createAdSessionContext(withPartner: partner, adUnit: adUnit, adView: adView)

        // Obtain ad session configuration. Configuration may be different depending on the type of the ad unit.
        let configuration = createAdSessionConfiguration(adUnit: adUnit)

        do {
            // Create ad session
            let session = try OMIDDocereeAdSession(configuration: configuration, adSessionContext: context)

            print("Session created for \(adUnit.title)")
            // Only add adView if not nativeAudio adUnit
            if adUnit == .nativeAudio {
                return session
            }

            // Provide main ad view for measurement
            guard let adView = adView else {
                fatalError("Ad View is not initialized")
            }
            session.mainAdView = adView
            return session
        } catch {
            fatalError("Unable to instantiate ad session: \(error)")
        }

    }

    private static func createAdSessionContext(withPartner partner: OMIDDocereePartner, adUnit: AdUnit, adView: UIView?) -> OMIDDocereeAdSessionContext {
        do {
            switch adUnit {
            case .HTMLDisplay, .HTMLVideo, .JSDisplay, .JSVideo:
                fatalError("Not supported in tvOS")
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
                    fatalError("Unable to instantiate session context: verification resource cannot be nil")
                }


                return try OMIDDocereeAdSessionContext(partner: partner,
                                                script: omidJSService,
                                                resources: [verificationResource],
                                                contentUrl: nil,
                                                customReferenceIdentifier: nil)
            }
        } catch {
            fatalError("Unable to create ad session context: \(error)")
        }
    }


#else

    /// Creates an OMID Utility object for an HTML ad
    /// - Parameters:
    ///   - adUnit: The type of ad
    ///   - webCreative: The webView where the ad creative and the OMID context is running
    convenience init(adUnit: AdUnit, webCreative: WKWebView) {
        self.init(adUnit: adUnit, adView: webCreative, webViewContext: webCreative)
    }

    /// Creates an OMID Utility object
    /// - Parameters:
    ///   - adUnit: The type of ad
    ///   - adView: The ad view
    ///   - webViewContext: The webView where the OMID Context is running if not managed natively.
    init(adUnit: AdUnit, adView: UIView? = nil, webViewContext: WKWebView? = nil) {
        self.adUnit = adUnit
        self.adView = adView
        self.webViewContext = webViewContext
        self.adSession = OMIDSessionInteractor.createAdSession(adUnit: adUnit, adView: adView, omidJSContext: webViewContext)
    }

    private static func createAdSession(adUnit: AdUnit, adView: UIView?, omidJSContext: WKWebView?) -> OMIDDocereeAdSession {
        // ensure OMID has been already activated
        guard OMIDDocereeSDK.shared.isActive else {
            fatalError("OMID is not active")
        }

        // Obtain ad session context. The context may be different depending on the type of the ad unit.
        let context = createAdSessionContext(withPartner: partner, adUnit: adUnit, adView: adView,  omidJSContext: omidJSContext)

        // Obtain ad session configuration. Configuration may be different depending on the type of the ad unit.
        let configuration = createAdSessionConfiguration(adUnit: adUnit)

        do {
            // Create ad session
            let session = try OMIDDocereeAdSession(configuration: configuration, adSessionContext: context)

            print("Session created for \(adUnit.title)")
            // Only add adView if not nativeAudio adUnit
            if adUnit == .nativeAudio {
                return session
            }

            // Provide main ad view for measurement
            guard let adView = adView else {
                fatalError("Ad View is not initialized")
            }
            session.mainAdView = adView
            return session
        } catch {
            fatalError("Unable to instantiate ad session: \(error)")
        }

    }

    private static func createAdSessionContext(withPartner partner: OMIDDocereePartner, adUnit: AdUnit, adView: UIView?, omidJSContext: WKWebView?) -> OMIDDocereeAdSessionContext {
        do {
            switch adUnit {
            case .HTMLDisplay, .HTMLVideo:
                guard let webView = omidJSContext else {
                    fatalError("Unable to create ad session context: webView is not initialized")
                }
                return try OMIDDocereeAdSessionContext(partner: partner,
                                                webView: webView,
                                                contentUrl: nil,
                                                customReferenceIdentifier: nil)
            case .JSDisplay, .JSVideo:
                guard let webView = omidJSContext else {
                    fatalError("Unable to create ad session context: webView is not initialized")
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
                    fatalError("Unable to instantiate session context: verification resource cannot be nil")
                }


                return try OMIDDocereeAdSessionContext(partner: partner,
                                                script: omidJSService,
                                                resources: [verificationResource],
                                                contentUrl: nil,
                                                customReferenceIdentifier: nil)
            }
        } catch {
            fatalError("Unable to create ad session context: \(error)")
        }

    }
    #endif



    private static func createAdSessionConfiguration(adUnit: AdUnit) -> OMIDDocereeAdSessionConfiguration {
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
            fatalError("Unable to create ad session configuration: \(error)")
        }
    }

    private func createAdEventsPublisher() {
        // Create event publisher before starting the session
        do {
            self.adEvents = try OMIDDocereeAdEvents(adSession: adSession)
        } catch {
            fatalError("Unable to instantiate OMIDAdEvents: \(error)")
        }
    }

    private func createMediaEventsPublisher() {
        if adUnit.generatesNativeMediaEvents {
            do {
                self.mediaEvents = try OMIDDocereeMediaEvents(adSession: adSession)
            } catch {
                fatalError("Unable to instantiate OMIDMediaEvents: \(error)")
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
            fatalError("Unable to parse Verification Script URL")
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
        print("Starting session for \(adSession.debugDescription), \(adUnit.title)")

        createAdEventsPublisher()
        createMediaEventsPublisher()

        adSession.start()
    }

    func addCloseButtonObstruction(_ button: UIView) {
        print("Adding close button obstruction for \(adUnit.title)")
        do {
            try adSession.addFriendlyObstruction(button,
                                                 purpose: .closeAd,
                                                 detailedReason: "Close Ad Button")
        } catch {
            fatalError("Unable to add friendly obstruction \(error.localizedDescription)")
        }
    }

    func fireAdLoaded() {
        print("Firing ad loaded \(adUnit.title)")
        do {

            try getAdEventsPublisher().loaded()
        }
        catch {
            fatalError("OMID load error: \(error.localizedDescription)")
        }
    }

    func fireAdLoaded(vastProperties: OMIDDocereeVASTProperties) {
        print("Firing ad loaded \(adUnit.title)")
        do {
            try getAdEventsPublisher().loaded(with: vastProperties)
        }
        catch {
            fatalError("OMID load error: \(error.localizedDescription)")
        }
    }

    func fireImpression() {
        print("Firing impression for  \(adUnit.title)")
        do {
            try getAdEventsPublisher().impressionOccurred()
        } catch {
            fatalError("OMID impression error: \(error.localizedDescription)")
        }
    }

    func stopSession() {
        print("Stopping the session \(adUnit.title)")
        adSession.finish()
    }

    func getMediaEventsPublisher() -> OMIDDocereeMediaEvents {
        guard let mediaEvents = self.mediaEvents else {
            fatalError("OMIDMediaEvents not instantiated, should start the session first")
        }

        return mediaEvents
    }

    func getAdEventsPublisher() -> OMIDDocereeAdEvents {
        guard let adEvents = self.adEvents else {
            fatalError("OMIDMediaEvents not instantiated, should start the session first")
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
        print("Simulating OMID SDK Javascript download ...")
    }

//    static var omidJSService: String {
//        let omidServiceUrl = Bundle.main.url(forResource: "omsdk-v1", withExtension: "js")!
//        return try! String(contentsOf: omidServiceUrl)
//    }
    
    static var omidJSService: String {
        guard let bundleURL = Bundle(for: HcpValidationView.self).url(forResource: "DocereeAdsSdk", withExtension: "bundle"),
              let bundle = Bundle(url: bundleURL),
              let omidServiceUrl = bundle.url(forResource: "omsdk-v1", withExtension: "js") else {
            fatalError("❌ Could not locate omsdk-v1.js in DocereeAdsSdk.bundle")
        }

        do {
            return try String(contentsOf: omidServiceUrl)
        } catch {
            fatalError("❌ Failed to load contents of omsdk-v1.js: \(error)")
        }
    }

    
}
