//
//  PatientSessionApi.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 30/05/24.
//

import Foundation

class PatientSessionApi {

    static func send(sessionId: String = "", status: Int = 0) async throws {
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

        try await sendRequest(url: url, headers: headerJson)
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

    private static func sendRequest(url: URL, headers: [String: String]) async throws {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            DocereeLog.debug("PatientSessionApi response: \(statusCode)")
            guard statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
        } catch {
            DocereeLog.debug("PatientSessionApi: request failed: \(error)")
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
