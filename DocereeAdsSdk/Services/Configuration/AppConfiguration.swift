//
//  AppConfiguration.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 12/05/25.
//

import Foundation

struct AppConfiguration: Codable {
    let timestamp: String
    let code: Int
    let status: String
    let message: String
    let data: AppConfigurationData
}

struct AppConfigurationData: Codable {
    let hcpValidation: Bool
    let ketchConsent: Bool
    let appId: String
    let platformId: Int?
}

/// Thrown when app configuration cannot be loaded from the network or decoded.
public enum AppConfigurationServiceError: Error {
    case invalidHTTPResponse
    case httpStatusNotSuccess(statusCode: Int, responseBodyPreview: String?)
    case decodingFailed(underlying: Error, responseBodyPreview: String?)
}

extension AppConfigurationServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidHTTPResponse:
            return "App configuration request returned a non-HTTP response."
        case .httpStatusNotSuccess(let statusCode, let preview):
            var message = "App configuration HTTP status \(statusCode) was not successful."
            if let preview, !preview.isEmpty {
                message += " Response preview: \(preview)"
            }
            return message
        case .decodingFailed(let underlying, let preview):
            var message = "Unable to decode app configuration: \(underlying.localizedDescription)"
            if let preview, !preview.isEmpty {
                message += ". Response preview: \(preview)"
            }
            return message
        }
    }
}

/// Result of `ConfigurationService.fetchAppConfiguration(appId:)` so callers do not mix `nil` skips with thrown errors.
enum AppConfigurationFetchOutcome: Sendable {
    /// Cached configuration is still valid; no network request was made.
    case usedValidCache
    /// The hosting task was cancelled before a result was committed (no partial persistence after a successful decode).
    case cancelled
    /// No application key was found on disk; the API was not called.
    case missingApplicationKey
    /// The configuration URL could not be built for the current environment and host.
    case invalidConfigurationURL(environment: EnvironmentType, identityHost: String)
    /// Request body could not be encoded (e.g. JSON serialization failure).
    case requestEncodingFailed(underlying: Error)
    /// Network, HTTP status, or JSON decode failed after a request was attempted.
    case fetchFailed(underlying: Error)
    /// New configuration was downloaded and persisted.
    case refreshed(AppConfiguration)
}
