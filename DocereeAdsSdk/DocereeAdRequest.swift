// RefactoredDocereeAdRequest.swift
// Refactored for Combine + Async/Await & Clean Architecture

import Foundation
import UIKit
import Combine
import os.log

// MARK: - Protocol Definitions
protocol AdServiceProtocol {
    func requestAd(userId: String?, adUnitId: String, size: String) async throws -> (Results, Bool)
    func sendImpression(to url: String)
    func sendViewability(to url: String)
    func sendAdBlock(advertiserCampID: String?, blockLevel: String?, platformUid: String?, publisherACSID: String?)
}

// MARK: - AdService Implementation
public final class DocereeAdRequest: AdServiceProtocol {

    // MARK: - Shared Instance
    internal static let shared = DocereeAdRequest()
    public init() {}

    // MARK: - Dependencies
    private let session = URLSession.shared
    private var requestHttpHeaders = RestEntity()
    var isVendorId: Bool = false

    // MARK: - Public Methods
    internal func requestAd(userId: String?, adUnitId: String, size: String) async throws -> (Results, Bool) {
        guard let appKey = DocereeMobileAds().loadDocereeIdentifier(from: DocereeAdsIdArchivingUrl) else {
            throw DocereeAdRequestError.invalidAppKey
        }

        let id: String?
        if let userId = userId, !userId.isEmpty {
            id = userId
        } else {
            id = getIdentifierForAdvertising()
        }
        
//        guard let advertisementId = userId ?? getIdentifierForAdvertising() else {
//            throw DocereeAdRequestError.adTrackingDisabled
//        }

        guard let loggedInUser = DocereeMobileAds.shared().getProfile() else {
            throw DocereeAdRequestError.invalidUserProfile
        }

        let body: [String: Any] = makeAdRequestBody(appKey: appKey, userId: id!, user: loggedInUser, adUnitId: adUnitId)
        let urlRequest = try makeRequest(advertisementId: id, path: getPath(methodName: Methods.GetImage), host: getHost(type: DocereeMobileAds.shared().getEnvironment()), body: body)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DocereeAdRequestError.failedToCreateRequest
        }

        let decoded = try JSONDecoder().decode(AdResponseMain.self, from: data)
        guard let adResponse = decoded.response.first, adResponse.errMessage?.isEmpty ?? true else {
            throw DocereeAdRequestError.adServerReturnedError
        }

        return (Results(withData: data, response: httpResponse, error: nil), adResponse.isAdRichMedia())
    }

    internal func sendImpression(to url: String) {
        guard let url = URL(string: url) else { return }
        let request = URLRequest(url: url)
        sendBeacon(request, "Impression")
    }

    internal func sendViewability(to url: String) {
        print("sendViewability: ", url)
        guard let url = URL(string: url) else { return }
        let request = URLRequest(url: url)
        sendBeacon(request, "Viewability")
    }

    internal func sendAdBlock(advertiserCampID: String?, blockLevel: String?, platformUid: String?, publisherACSID: String?) {
        let body: [String: Any] = [
            AdBlockService.advertiserCampID.rawValue: advertiserCampID ?? "",
            AdBlockService.blockLevel.rawValue: blockLevel ?? "",
            AdBlockService.platformUid.rawValue: platformUid ?? "",
            AdBlockService.publisherACSID.rawValue: publisherACSID ?? ""
        ]

        guard let request = try? makeRequest(
            advertisementId: nil, path: getPath(methodName: Methods.AdBlock),
            host: getDocTrackerHost(type: DocereeMobileAds.shared().getEnvironment()),
            body: body
        ) else { return }

        sendBeacon(request, "Ad Block")
    }

    // MARK: - Helper Methods
    private func makeAdRequestBody(appKey: String, userId: String, user: Hcp, adUnitId: String) -> [String: Any] {
        let consentData = UserDefaultsManager.shared.getConsentData()
        return [
            QueryParamsForAdRequest.appKey.rawValue: appKey,
            QueryParamsForAdRequest.userId.rawValue: userId,
            QueryParamsForAdRequest.email.rawValue: user.email ?? "",
            QueryParamsForAdRequest.firstName.rawValue: user.firstName ?? "",
            QueryParamsForAdRequest.lastName.rawValue: user.lastName ?? "",
            QueryParamsForAdRequest.specialization.rawValue: user.specialization ?? "",
            QueryParamsForAdRequest.hcpId.rawValue: user.hcpId ?? "",
            QueryParamsForAdRequest.hashedHcpId.rawValue: user.hashedHcpId ?? "",
            QueryParamsForAdRequest.gender.rawValue: user.gender ?? "",
            QueryParamsForAdRequest.city.rawValue: user.city ?? "",
            QueryParamsForAdRequest.state.rawValue: user.state ?? "",
            QueryParamsForAdRequest.country.rawValue: user.country ?? "",
            QueryParamsForAdRequest.zipCode.rawValue: user.zipCode ?? "",
            QueryParamsForAdRequest.adUnit.rawValue: adUnitId,
            QueryParamsForAdRequest.br.rawValue : PatientSession().getBr(),
            QueryParamsForAdRequest.cdt.rawValue: "",
            QueryParamsForAdRequest.privacyConsent.rawValue: 1,
            QueryParamsForAdRequest.userPreference.rawValue: consentData.isPersonalizeAd,
            QueryParamsForAdRequest.privacyType.rawValue: consentData.privacyComplianceType,
            QueryParamsForAdRequest.privacyString.rawValue: consentData.privacyString
        ]
    }

    private func makeRequest(advertisementId: String?, path: String, host: String, body: [String: Any]) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        guard let url = components.url else {
            throw DocereeAdRequestError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.post.rawValue
        self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
        self.requestHttpHeaders.add(value: UAString.init().UAString(), forKey: HeaderEnum.header_user_agent.rawValue)
        self.requestHttpHeaders.add(value: advertisementId ?? "", forKey: HeaderEnum.header_advertising_id.rawValue)
        self.requestHttpHeaders.add(value: self.isVendorId ? "1" : "0", forKey: HeaderEnum.is_vendor_id.rawValue)
        self.requestHttpHeaders.add(value: DocereeMobileAds.trackingStatus, forKey: HeaderEnum.header_is_ad_tracking_enabled.rawValue)
        self.requestHttpHeaders.add(value: Bundle.main.displayName!, forKey: HeaderEnum.header_app_name.rawValue)
        self.requestHttpHeaders.add(value: Bundle.main.bundleIdentifier!, forKey: HeaderEnum.header_app_bundle.rawValue)
        self.requestHttpHeaders.add(value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String, forKey: HeaderEnum.header_app_version.rawValue)
        self.requestHttpHeaders.add(value: Utils().version(), forKey: HeaderEnum.header_lib_version.rawValue)

        
        for header in requestHttpHeaders.allValues() {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        return request
    }

    private func sendBeacon(_ request: URLRequest, _ message: String) {
        session.dataTask(with: request) { data, response, _ in
            #if DEBUG
            if let httpResponse = response as? HTTPURLResponse {
                print("\(message) Sent with Status: \(httpResponse.statusCode)")
            }
            #endif
        }.resume()
    }
}

// MARK: - Extensions
extension Data {
    func printJSON() {
        if let JSONString = String(data: self, encoding: .utf8) {
            print(JSONString)
        }
    }
}
