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
