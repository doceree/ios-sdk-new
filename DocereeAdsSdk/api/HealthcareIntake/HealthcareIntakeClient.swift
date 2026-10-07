//
//  HealthcareIntakeClient.swift
//  DocereeAdsSdk
//
//  Standalone healthcare intake API — not connected to ad-server, PatientSession, or DocereeMobileAds.
//

import Foundation

struct HealthcareIntakeResponse: Equatable {
    let accepted: Bool
    let requestId: String

    init(json: [String: Any]) {
        let data = json["data"] as? [String: Any] ?? [:]
        accepted = data["accepted"] as? Bool ?? false

        let nestedRequestId = Self.normalizedRequestId(data["request_id"])
        let topLevelRequestId = Self.normalizedRequestId(json["request_id"])
        requestId = nestedRequestId ?? topLevelRequestId ?? ""
    }

    private static func normalizedRequestId(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public enum HealthcareIntakeError: Error, LocalizedError {
    case invalidURL
    case requestEncodingFailed(underlying: Error)
    case invalidHTTPResponse
    case httpStatusNotSuccess(statusCode: Int)
    case responseDecodingFailed
    case intakeRejected(requestId: String)

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
        case .responseDecodingFailed:
            return "Healthcare intake returned a response that could not be parsed."
        case .intakeRejected(let requestId):
            if requestId.isEmpty {
                return "Healthcare intake rejected the request."
            }
            return "Healthcare intake rejected the request (request_id: \(requestId))."
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

        let (data, response) = try await urlSession.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw HealthcareIntakeError.invalidHTTPResponse
        }
        guard (200...299).contains(http.statusCode) else {
            DocereeLog.debug("HealthcareIntakeClient HTTP \(http.statusCode)")
            throw HealthcareIntakeError.httpStatusNotSuccess(statusCode: http.statusCode)
        }

        let bodyText = String(data: data, encoding: .utf8) ?? ""
        DocereeLog.debug("HealthcareIntakeClient response: \(http.statusCode) \(bodyText)")

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HealthcareIntakeError.responseDecodingFailed
        }

        let intakeResponse = HealthcareIntakeResponse(json: json)
        guard intakeResponse.accepted else {
            throw HealthcareIntakeError.intakeRejected(requestId: intakeResponse.requestId)
        }

        HealthcareIntakeRequestIdStore.save(intakeResponse.requestId)
    }
}

extension HealthcareIntakeClient: @unchecked Sendable {}
