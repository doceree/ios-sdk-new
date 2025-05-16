//
//  AdUnit.swift
//  AppVerificationLibrary
//
//  Created by Michele Simone on 03/01/2023.
//  Copyright © 2023 IAB Techlab. All rights reserved.
//

import Foundation

/**
 Supported Ad Units
 */
enum AdUnit: CaseIterable {

    /// Standard 300x250 HTML display banner rendered by WKWebView.
    case HTMLDisplay

    /// A video asset rendered by WKWebView
    case HTMLVideo

    /// A static image rendered by UIImageView
    case nativeDisplay

    /// A video asset rendered by AVKit
    case nativeVideo

    /// An audio ad played with AVPlayer
    case nativeAudio

    case JSDisplay

    case JSVideo

    var title: String {
        switch self {
        case .HTMLDisplay:
            return "HTML Display"
        case .HTMLVideo:
            return "HTML Video"
        case .nativeDisplay:
            return "Native Display"
        case .nativeVideo:
            return "Native Video"
        case .nativeAudio:
            return "Native Audio"
        case .JSDisplay:
            return "JavaScript Display"
        case .JSVideo:
            return "JavaScript Video"
        }
    }

//    var segue: String {
//        switch self {
//        case .HTMLDisplay:
//            return "showBanner"
//        case .HTMLVideo:
//            return "showHTMLVideo"
//        case .nativeDisplay:
//            return "showNativeBanner"
//        case .nativeVideo:
//            return "showVideo"
//        case .nativeAudio:
//            return "showAudio"
//        case .JSDisplay:
//            return "showJSBanner"
//        case .JSVideo:
//            return "showJSVideo"
//        }
//    }


}

#if os(tvOS)
// When running on tvOS we need to restrict the AdUnit to native only as
// tvOs restrict the access to `wkWebview`
extension AdUnit {
    static var allCases: Self.AllCases {
        return [.nativeDisplay, .nativeVideo, .nativeAudio]
    }
}
#endif


extension AdUnit {

    /// Identify which ad units can generate `MediaEvents`
    var generatesNativeMediaEvents: Bool {
        switch self {
        case .nativeVideo, .nativeAudio, .JSVideo:
            return true
        default:
            return false
        }
    }
}
