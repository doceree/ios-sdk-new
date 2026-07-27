//
//  HealthcareIntakeClient.swift
//  DocereeAdsSdk
//
//  Standalone healthcare intake API — not connected to ad-server, PatientSession, or DocereeMobileAds.
//

import Foundation

public enum HealthcareIntakeError: Error, LocalizedError {
    case invalidURL
    case requestEncodingFailed(underlying: Error)
    case invalidHTTPResponse
    case httpStatusNotSuccess(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to build the healthcare intake URL."
        case .requestEncodingFailed(let underlying):
            return "Unable to encode healthcare intake payload: \(underlying.localizedDescription)"
        case .invalidHTTPResponse:
            return "Healthcare intake request returned a non-HTTP response."
        case .httpStatusNotSuccess(let statusCode):
            return "Healthcare intake HTTP status \(statusCode) was not successful."
        }
    }
}

public final class HealthcareIntakeClient {
    public static let shared = HealthcareIntakeClient()

    private static let requestTimeout: TimeInterval = 30
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Builds the intake payload from app-provided patient JSON and POSTs it to the SDK healthcare intake endpoint.
    public func submitPatientIntake(patientDetails: [String: Any]) async throws {
        let payload = HealthcareIntakePayloadBuilder.build(from: patientDetails)
        try await submitIntakePayload(payload)
    }

    /// POSTs a fully-built intake JSON body to the SDK healthcare intake endpoint.
    public func submitIntakePayload(_ payload: [String: Any]) async throws {
        let url = HealthcareIntakeEndpoint.url

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = Self.requestTimeout
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw HealthcareIntakeError.requestEncodingFailed(underlying: error)
        }

        let (_, response) = try await urlSession.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw HealthcareIntakeError.invalidHTTPResponse
        }
        guard (200...299).contains(http.statusCode) else {
            DocereeLog.debug("HealthcareIntakeClient HTTP \(http.statusCode)")
            throw HealthcareIntakeError.httpStatusNotSuccess(statusCode: http.statusCode)
        }
        DocereeLog.debug("HealthcareIntakeClient response: \(http.statusCode)")
    }
}

extension HealthcareIntakeClient: @unchecked Sendable {}
