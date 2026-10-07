//
//  PatientSessionApi.swift
//  DocereeAdsSdk
//

import Foundation

class PatientSessionApi {

    static func send(sessionId: String = "", status: Int = 0) async {
        do {
            let headerJson = try await fetchHeaders()

            guard let hcpData = DocereeMobileAds.shared().getProfile() else {
                DocereeLog.debug("PatientSessionApi: profile data not found")
                return
            }

            guard
                let userIdentifier = getIdentifierForAdvertising(),
                let hcpIdentifier = hcpData.hcpId
            else {
                DocereeLog.debug("PatientSessionApi: uid or hid is nil")
                return
            }

            guard let url = PatientSessionEndpoint.buildURL(
                mode: DocereeMobileAds.shared().getEnvironment(),
                userIdentifier: userIdentifier,
                sessionIdentifier: sessionId,
                hcpIdentifier: hcpIdentifier,
                status: status
            ) else {
                DocereeLog.debug("PatientSessionApi: failed to build session URL")
                return
            }

            var request = URLRequest(url: url)
            request.allHTTPHeaderFields = headerJson
            request.timeoutInterval = DocereeHTTPTimeouts.interactiveRequest
            DocereeBeaconQueue.sendRequestOrEnqueue(kind: .session, request: request, sessionId: sessionId)
        } catch {
            DocereeLog.debug("PatientSessionApi: session ping queued or failed: \(error)")
        }
    }

    private static func fetchHeaders() async throws -> [String: String] {
        do {
            let headerJson = try await Header().getHeaders()
            DocereeLog.debug("PatientSessionApi: fetched headers: \(headerJson)")
            return headerJson
        } catch {
            DocereeLog.debug("PatientSessionApi: error fetching headers: \(error)")
            throw error
        }
    }
}

private enum PatientSessionEndpoint {
    private static let patientSessionPath = "/drs/nEvent"
    private static let eventType = "4"

    static func buildURL(
        mode: EnvironmentType,
        userIdentifier: String,
        sessionIdentifier: String,
        hcpIdentifier: String,
        status: Int
    ) -> URL? {
        let baseURL = baseURL(mode: mode)
        guard var components = URLComponents(string: "\(baseURL)\(patientSessionPath)") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "uid", value: userIdentifier),
            URLQueryItem(name: "sid", value: sessionIdentifier),
            URLQueryItem(name: "hid", value: hcpIdentifier),
            URLQueryItem(name: "status", value: String(status)),
            URLQueryItem(name: "eType", value: eventType)
        ]

        return components.url
    }

    private static func baseURL(mode: EnvironmentType) -> String {
        switch mode {
        case .Dev:
            return "https://dev-bidder.doceree.com"
        case .Qa:
            return "https://qa-ad-test.doceree.com"
        case .Prod, .Local:
            return "https://dai.doceree.com"
        }
    }
}
