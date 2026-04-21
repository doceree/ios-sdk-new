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
