//
//  ConfigurationService.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 12/05/25.
//

import Foundation

class ConfigurationService {
    static let shared = ConfigurationService()
    
    func fetchAppConfiguration(appId: String) async throws -> AppConfiguration? {
        // Check if config is still valid
        if UserDefaultsManager.shared.isConfigValid() {
            print("Config still valid")
            return nil
        } else {
            print("Config expired, refresh needed")
        }
        
//        let host = getHost(type: DocereeMobileAds.shared().getEnvironment())
        let host = getDataCollectionHost(type: EnvironmentType.Qa)
        guard let appKey = DocereeMobileAds().loadDocereeIdentifier(from: DocereeAdsIdArchivingUrl) else {
            // Handle missing key
            return nil
        }
        
        UserDefaultsManager.shared.deleteConfig()
        UserDefaultsManager.shared.clearConfigExpiration()
        
        let url = URL(string: "https://\(host ?? "")\(getPath(methodName: Methods.AppConfig))")!
        print("url: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appKey, forHTTPHeaderField: "X-Requested-With")
        
        let body = ["appId": appId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        do {
            let decoded = try JSONDecoder().decode(AppConfiguration.self, from: data)
            UserDefaultsManager.shared.saveConfigExpiration()
            UserDefaultsManager.shared.saveConfig(decoded.data)
        } catch {
            print("Data is not of type AppConfigurationData:", error)
        }
        return try JSONDecoder().decode(AppConfiguration.self, from: data)
    }
}
