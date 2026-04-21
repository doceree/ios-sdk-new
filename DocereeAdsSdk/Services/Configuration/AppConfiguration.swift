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

/// Thrown when an app-configuration HTTP response cannot be decoded as `AppConfiguration`.
public enum AppConfigurationServiceError: Error {
    case decodingFailed(underlying: Error, responseBodyPreview: String?)
}

extension AppConfigurationServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .decodingFailed(let underlying, let preview):
            var message = "Unable to decode app configuration: \(underlying.localizedDescription)"
            if let preview, !preview.isEmpty {
                message += ". Response preview: \(preview)"
            }
            return message
        }
    }
}
