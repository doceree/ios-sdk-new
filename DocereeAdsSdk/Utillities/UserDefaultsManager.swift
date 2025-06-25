
final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard
    private init() {}

    // MARK: - Internal Keys
    private let configExpirationKey = "configExpirationDate"
    private let hcpValidationExpirationKey = "hcpValidationExpirationDate"
    private let appConfigKey = "appConfigData"

    // MARK: - Config Expiration (always 24 hours)

    func saveConfigExpiration() {
        let expirationDate = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        defaults.set(expirationDate, forKey: configExpirationKey)
    }

    func isConfigValid() -> Bool {
        guard let expirationDate = defaults.object(forKey: configExpirationKey) as? Date else {
            return false
        }
        return Date() < expirationDate
    }

    func clearConfigExpiration() {
        defaults.removeObject(forKey: configExpirationKey)
    }

    // MARK: - HCP Validation Expiration (variable durations)

    func saveHCPValidationExpiration(duration: TimeInterval) {
        let expirationDate = Date().addingTimeInterval(duration)
        defaults.set(expirationDate, forKey: hcpValidationExpirationKey)
    }

    func isHCPValidationValid() -> Bool {
        guard let expirationDate = defaults.object(forKey: hcpValidationExpirationKey) as? Date else {
            return false
        }
        return Date() < expirationDate
    }

    func clearHCPValidationExpiration() {
        defaults.removeObject(forKey: hcpValidationExpirationKey)
    }
   
    // MARK: - App Config Storage
    
    func saveConfig(_ config: AppConfigurationData) {
        do {
            let data = try JSONEncoder().encode(config)
            defaults.set(data, forKey: appConfigKey)
        } catch {
            print("Failed to encode AppConfigurationData:", error)
        }
    }
    
    func loadConfig() -> AppConfigurationData? {
        guard let data = defaults.data(forKey: appConfigKey) else { return nil }
        do {
            return try JSONDecoder().decode(AppConfigurationData.self, from: data)
        } catch {
            print("Failed to decode AppConfigurationData:", error)
            return nil
        }
    }
    
    func deleteConfig() {
        defaults.removeObject(forKey: appConfigKey)
    }

}
