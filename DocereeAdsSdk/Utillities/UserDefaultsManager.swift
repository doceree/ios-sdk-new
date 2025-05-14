import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let defaults = UserDefaults.standard
    
    private let defaultsKey = "YourUserDefaultsKey"
    var expirationDuration: TimeInterval = ExpirationDuration.hours6
    
    private var saveTimeWithInterval: TimeInterval? {
        get {
            return defaults.object(forKey: "lastSetTime") as? TimeInterval
        }
        set {
            defaults.set(newValue, forKey: "lastSetTime")
        }
    }
    
    private init() {}
    
    func setUserDefaults(_ value: TimeInterval) {
        defaults.set(value, forKey: defaultsKey)
        saveTimeWithInterval = Date.currentTimeInterval() + (value * 1000) //Date() // Record the time when user defaults were set
    }
    
    func getUserDefaults() -> Any? {
        // Check if user defaults have expired
        if let lastSetTime = saveTimeWithInterval, lastSetTime < Date.currentTimeInterval() {
            // User defaults have expired, delete them
            deleteUserDefaults()
            return nil
        }
        return defaults.object(forKey: defaultsKey)
    }
    
    func deleteUserDefaults() {
        defaults.removeObject(forKey: defaultsKey)
        // Optionally, reset lastSetTime to nil or another appropriate value
        saveTimeWithInterval = nil
    }
    
    func saveAppConfigurationToDefaults(_ config: AppConfigurationData) {
        do {
            let data = try JSONEncoder().encode(config)
            UserDefaults.standard.set(data, forKey: "AppConfiguration")
        } catch {
            print("Failed to encode AppConfigurationData:", error)
        }
    }

    func loadAppConfigurationFromDefaults() -> AppConfigurationData? {
        if let data = UserDefaults.standard.data(forKey: "AppConfiguration") {
            do {
                return try JSONDecoder().decode(AppConfigurationData.self, from: data)
            } catch {
                print("Failed to decode AppConfigurationData:", error)
            }
        }
        return nil
    }

}
