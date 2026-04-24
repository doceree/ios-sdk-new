// RefactoredDocereeAdRequest.swift
// Refactored for Combine + Async/Await & Clean Architecture

import Foundation
import UIKit
import Combine
import os.log

/// Thrown internally for non-success ad HTTP responses; mapped to `DocereeAdRequestError` at the `requestAd` boundary. Exposed as `internal` for unit tests.
internal enum AdRequestTransportFailure: Error {
    case invalidHTTPResponse
    case unacceptableHTTPStatus(code: Int, bodyPreview: String?)
}

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

    // MARK: - Dependencies
    private let session: URLSession
    private var requestHttpHeaders = RestEntity()
    var isVendorId: Bool = false

    public init(urlSession: URLSession = .shared) {
        self.session = urlSession
    }

    // MARK: - Public Methods
    internal func requestAd(userId: String?, adUnitId: String, size: String) async throws -> (Results, Bool) {
        let signpost = DocereeSignposts.adRequestInterval("doceree.request_ad")
        defer { signpost.end() }
        try Task.checkCancellation()

        guard let appKey = DocereeMobileAds().loadDocereeIdentifier(from: DocereeAdsIdArchivingUrl) else {
            throw DocereeAdRequestError.invalidAppKey
        }

        let id: String?
        if let userId = userId, !userId.isEmpty {
            id = userId
        } else {
            id = getIdentifierForAdvertising()
        }

        guard let loggedInUser = DocereeMobileAds.shared().getProfile() else {
            throw DocereeAdRequestError.invalidUserProfile
        }

        let body: [String: Any] = makeAdRequestBody(appKey: appKey, userId: id!, user: loggedInUser, adUnitId: adUnitId)
        var urlRequest = try makeRequest(
            advertisementId: id,
            path: getPath(methodName: Methods.GetImage, type: DocereeMobileAds.shared().getEnvironment()),
            host: getHost(type: DocereeMobileAds.shared().getEnvironment()),
            body: body
        )
        urlRequest.timeoutInterval = DocereeHTTPTimeouts.interactiveRequest

        let (data, httpResponse) = try await performAdNetworkFetchWithRetries(urlRequest)
        try Task.checkCancellation()
        do {
            let decoded = try JSONDecoder().decode(AdResponseMain.self, from: data)
            guard let adResponse = decoded.response.first, adResponse.errMessage?.isEmpty ?? true else {
                throw DocereeAdRequestError.adServerReturnedError
            }
            return (Results(withData: data, response: httpResponse, error: nil), adResponse.isAdRichMedia())
        } catch let known as DocereeAdRequestError {
            throw known
        } catch {
            DocereeLog.debug("Ad request decode failed: \(error.localizedDescription)")
            throw DocereeAdRequestError.adServerReturnedError
        }
    }

    /// HTTP layer only: validates response, retries transient 5xx / `URLError`s. Used by `requestAd` and by unit tests via `URLProtocol`.
    internal func performAdNetworkFetchWithRetries(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        for attempt in 0..<DocereeHTTPTransportRetry.maxAttempts {
            try Task.checkCancellation()
            do {
                return try await fetchAdHTTPDataOnce(urlRequest)
            } catch is CancellationError {
                throw CancellationError()
            } catch let transport as AdRequestTransportFailure {
                switch transport {
                case .invalidHTTPResponse:
                    throw DocereeAdRequestError.nonHTTPResponse
                case .unacceptableHTTPStatus(let code, let preview):
                    DocereeLog.debug("Ad request HTTP \(code) preview: \(preview ?? "")")
                    if DocereeHTTPTransportRetry.shouldRetry(httpStatusCode: code), attempt < DocereeHTTPTransportRetry.maxAttempts - 1 {
                        DocereeLog.debug("Ad request: retrying after HTTP \(code)")
                        try await Task.sleep(nanoseconds: DocereeHTTPTransportRetry.backoffNanoseconds(afterFailureAtAttempt: attempt))
                        continue
                    }
                    throw DocereeAdRequestError.httpUnsuccessful
                }
            } catch let urlError as URLError {
                if DocereeHTTPTransportRetry.shouldRetry(urlError: urlError), attempt < DocereeHTTPTransportRetry.maxAttempts - 1 {
                    DocereeLog.debug("Ad request: URLError \(urlError.code.rawValue), retrying")
                    try await Task.sleep(nanoseconds: DocereeHTTPTransportRetry.backoffNanoseconds(afterFailureAtAttempt: attempt))
                    continue
                }
                DocereeLog.debug("Ad request URLError \(urlError.code.rawValue): \(urlError.localizedDescription)")
                throw DocereeAdRequestError.failedToCreateRequest
            } catch {
                DocereeLog.debug("Ad request transport: \(error.localizedDescription)")
                throw DocereeAdRequestError.failedToCreateRequest
            }
        }
        throw DocereeAdRequestError.failedToCreateRequest
    }

    private func fetchAdHTTPDataOnce(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try Task.checkCancellation()
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AdRequestTransportFailure.invalidHTTPResponse
        }
        let status = httpResponse.statusCode
        guard (200...299).contains(status) else {
            let preview = String(data: data, encoding: .utf8).map { String($0.prefix(500)) }
            throw AdRequestTransportFailure.unacceptableHTTPStatus(code: status, bodyPreview: preview)
        }
        return (data, httpResponse)
    }

    internal func sendImpression(to url: String) {
        guard let url = URL(string: url) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = DocereeHTTPTimeouts.beaconRequest
        sendBeacon(request, "Impression")
    }

    internal func sendViewability(to url: String) {
        DocereeLog.debug("sendViewability: \(url)")
        guard let url = URL(string: url) else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = DocereeHTTPTimeouts.beaconRequest
        sendBeacon(request, "Viewability")
    }

    internal func sendAdBlock(advertiserCampID: String?, blockLevel: String?, platformUid: String?, publisherACSID: String?) {
        let body: [String: Any] = [
            AdBlockService.advertiserCampID.rawValue: advertiserCampID ?? "",
            AdBlockService.blockLevel.rawValue: blockLevel ?? "",
            AdBlockService.platformUid.rawValue: platformUid ?? "",
            AdBlockService.publisherACSID.rawValue: publisherACSID ?? ""
        ]

        guard var request = try? makeRequest(
            advertisementId: nil,
            path: getPath(methodName: Methods.AdBlock, type: DocereeMobileAds.shared().getEnvironment()),
            host: getDocTrackerHost(type: DocereeMobileAds.shared().getEnvironment()),
            body: body
        ) else { return }

        request.timeoutInterval = DocereeHTTPTimeouts.beaconRequest
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
        Task {
            await DocereeURLSessionBeacon.sendWithRetries(for: request, session: session, message: message)
        }
    }

}

// MARK: - Extensions
extension Data {
    func printJSON() {
        if let JSONString = String(data: self, encoding: .utf8) {
            DocereeLog.debug(JSONString)
        }
    }
}
