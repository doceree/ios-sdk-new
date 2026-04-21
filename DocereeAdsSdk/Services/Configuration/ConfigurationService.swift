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
    static func makeAppConfigurationURL(identityHost: String, environment: EnvironmentType) -> URL? {
        let path = getPath(methodName: Methods.AppConfig, type: environment)
        return URL(string: "https://\(identityHost)\(path)")
    }

    private static func responseBodyPreview(from data: Data, limit: Int = 500) -> String? {
        guard !data.isEmpty else { return nil }
        return String(data: data, encoding: .utf8).map { String($0.prefix(limit)) }
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
        
        let environment = DocereeMobileAds.shared().getEnvironment()
        let host = getIdentityHost(type: environment)
        guard let appKey = DocereeMobileAds().loadDocereeIdentifier(from: DocereeAdsIdArchivingUrl) else {
            // Handle missing key
            return nil
        }
        
        UserDefaultsManager.shared.deleteConfig()
        UserDefaultsManager.shared.clearConfigExpiration()
        
        guard let url = Self.makeAppConfigurationURL(identityHost: host, environment: environment) else {
            DocereeLog.debug("Invalid configuration URL (environment=\(environment), host=\(host))")
            return nil
        }
        DocereeLog.debug("App config fetch: environment=\(environment), url=\(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appKey, forHTTPHeaderField: "X-Requested-With")
        
        let body = ["appId": appId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            DocereeLog.debug("App config: non-HTTP response (environment=\(environment))")
            throw AppConfigurationServiceError.invalidHTTPResponse
        }
        let status = httpResponse.statusCode
        guard (200...299).contains(status) else {
            let preview = Self.responseBodyPreview(from: data)
            let err = AppConfigurationServiceError.httpStatusNotSuccess(statusCode: status, responseBodyPreview: preview)
            DocereeLog.debug("\(err.localizedDescription)")
            throw err
        }
        do {
            let decoded = try Self.decodeAppConfiguration(from: data)
            UserDefaultsManager.shared.saveConfigExpiration()
            UserDefaultsManager.shared.saveConfig(decoded.data)
            return decoded
        } catch {
            let preview = Self.responseBodyPreview(from: data)
            let wrapped = AppConfigurationServiceError.decodingFailed(underlying: error, responseBodyPreview: preview)
            DocereeLog.debug("\(wrapped.localizedDescription)")
            throw wrapped
        }
    }
}
