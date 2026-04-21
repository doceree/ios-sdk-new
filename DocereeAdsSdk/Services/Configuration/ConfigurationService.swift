//
//  ConfigurationService.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 12/05/25.
//

import Foundation

class ConfigurationService {
    static let shared = ConfigurationService()

    /// Builds the HTTPS URL used for app configuration fetch (same string as production).
    static func makeAppConfigurationURL(identityHost: String) -> URL? {
        URL(string: "https://\(identityHost)\(getPath(methodName: Methods.AppConfig))")
    }

    static func decodeAppConfiguration(from data: Data) throws -> AppConfiguration {
        try JSONDecoder().decode(AppConfiguration.self, from: data)
    }
    
    func fetchAppConfiguration(appId: String) async throws -> AppConfiguration? {
        // Check if config is still valid
        if UserDefaultsManager.shared.isConfigValid() {
            DocereeLog.debug("Config still valid")
            return nil
        } else {
            DocereeLog.debug("Config expired, refresh needed")
        }
        
        let host = getIdentityHost(type: DocereeMobileAds.shared().getEnvironment())
        guard let appKey = DocereeMobileAds().loadDocereeIdentifier(from: DocereeAdsIdArchivingUrl) else {
            // Handle missing key
            return nil
        }
        
        UserDefaultsManager.shared.deleteConfig()
        UserDefaultsManager.shared.clearConfigExpiration()
        
        guard let url = Self.makeAppConfigurationURL(identityHost: host) else {
            DocereeLog.debug("Invalid configuration URL for host: \(host)")
            return nil
        }
        DocereeLog.debug("url: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appKey, forHTTPHeaderField: "X-Requested-With")
        
        let body = ["appId": appId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        do {
            let decoded = try Self.decodeAppConfiguration(from: data)
            UserDefaultsManager.shared.saveConfigExpiration()
            UserDefaultsManager.shared.saveConfig(decoded.data)
            return decoded
        } catch {
            DocereeLog.debug("Data is not of type AppConfigurationData: \(error)")
            throw error
        }
    }
}
