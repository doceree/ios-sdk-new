
final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Internal Keys
    private let configExpirationKey = "configExpirationDate"
    private let hcpValidationExpirationKey = "hcpValidationExpirationDate"
    private let appConfigKey = "appConfigData"
    private let isPersonalizeAdKey = "isPersonalizeAd"
    private let privacyComplianceTypeKey = "privacyComplianceType"
    private let privacyComplianceVersionKey = "privacyComplianceVersion"
    private let privacyComplianceSIDKey = "privacyComplianceSID"
    private let privacyStringKey = "privacyString"
    private let hasExplicitConsentKey = "hasExplicitConsent"
    private let loggedInUserRoleKey = "docereeLoggedInUserRole"
    private let loggedInUserProfileKey = "docereeLoggedInUserProfile"
    private let consentStorageKey = "docereeConsent"

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
            DocereeLog.debug("Failed to encode AppConfigurationData: \(error)")
        }
    }
    
    func loadConfig() -> AppConfigurationData? {
        guard let data = defaults.data(forKey: appConfigKey) else { return nil }
        do {
            return try JSONDecoder().decode(AppConfigurationData.self, from: data)
        } catch {
            DocereeLog.debug("Failed to decode AppConfigurationData: \(error)")
            return nil
        }
    }
    
    func deleteConfig() {
        defaults.removeObject(forKey: appConfigKey)
    }

    // MARK: - Privacy Consent

    func saveConsent(_ consent: DocereeConsent) {
        let merged = (loadConsent() ?? DocereeConsent()).merging(consent)
        if merged.isEmpty {
            clearConsent()
            return
        }
        do {
            let data = try JSONEncoder().encode(merged)
            defaults.set(data, forKey: consentStorageKey)
        } catch {
            DocereeLog.debug("Failed to encode DocereeConsent: \(error)")
        }
    }

    func loadConsent() -> DocereeConsent? {
        guard let data = defaults.data(forKey: consentStorageKey) else { return nil }
        do {
            let consent = try JSONDecoder().decode(DocereeConsent.self, from: data)
            return consent.isEmpty ? nil : consent
        } catch {
            DocereeLog.debug("Failed to decode DocereeConsent: \(error)")
            return nil
        }
    }

    func clearConsent() {
        defaults.removeObject(forKey: consentStorageKey)
    }

    func hasStoredConsent() -> Bool {
        loadConsent() != nil
    }

    /// Legacy three-parameter consent API. Clears extended GPP fields so stale values are not forwarded.
    func setConsentData(isPersonalizeAd: String = "", privacyComplianceType: String = "", privacyString: String = "") {
        saveConsent(
            DocereeConsent.fromLegacyExplicit(
                isPersonalizeAd: isPersonalizeAd,
                privacyComplianceType: privacyComplianceType,
                privacyComplianceVersion: "",
                privacyComplianceSID: "",
                privacyString: privacyString
            )
        )
        defaults.set(isPersonalizeAd, forKey: isPersonalizeAdKey)
        defaults.set(privacyComplianceType, forKey: privacyComplianceTypeKey)
        defaults.set("", forKey: privacyComplianceVersionKey)
        defaults.set("", forKey: privacyComplianceSIDKey)
        defaults.set(privacyString, forKey: privacyStringKey)
        defaults.set(true, forKey: hasExplicitConsentKey)
    }

    func setConsentData(
        isPersonalizeAd: String,
        privacyComplianceType: String,
        privacyComplianceVersion: String,
        privacyComplianceSID: String,
        privacyString: String
    ) {
        saveConsent(
            DocereeConsent.fromLegacyExplicit(
                isPersonalizeAd: isPersonalizeAd,
                privacyComplianceType: privacyComplianceType,
                privacyComplianceVersion: privacyComplianceVersion,
                privacyComplianceSID: privacyComplianceSID,
                privacyString: privacyString
            )
        )
        defaults.set(isPersonalizeAd, forKey: isPersonalizeAdKey)
        defaults.set(privacyComplianceType, forKey: privacyComplianceTypeKey)
        defaults.set(privacyComplianceVersion, forKey: privacyComplianceVersionKey)
        defaults.set(privacyComplianceSID, forKey: privacyComplianceSIDKey)
        defaults.set(privacyString, forKey: privacyStringKey)
        defaults.set(true, forKey: hasExplicitConsentKey)
    }

    func hasExplicitConsent() -> Bool {
        defaults.bool(forKey: hasExplicitConsentKey)
    }

    func getExplicitConsentData() -> (
        isPersonalizeAd: String,
        privacyComplianceType: String,
        privacyComplianceVersion: String,
        privacyComplianceSID: String,
        privacyString: String
    ) {
        (
            defaults.string(forKey: isPersonalizeAdKey) ?? "",
            defaults.string(forKey: privacyComplianceTypeKey) ?? "",
            defaults.string(forKey: privacyComplianceVersionKey) ?? "",
            defaults.string(forKey: privacyComplianceSIDKey) ?? "",
            defaults.string(forKey: privacyStringKey) ?? ""
        )
    }

    /// Backward-compatible accessor used by older call sites.
    func getConsentData() -> (isPersonalizeAd: String, privacyComplianceType: String, privacyString: String) {
        let explicit = getExplicitConsentData()
        return (explicit.isPersonalizeAd, explicit.privacyComplianceType, explicit.privacyString)
    }

    func resetConsentForTesting() {
        [
            isPersonalizeAdKey,
            privacyComplianceTypeKey,
            privacyComplianceVersionKey,
            privacyComplianceSIDKey,
            privacyStringKey,
            hasExplicitConsentKey
        ].forEach { defaults.removeObject(forKey: $0) }
        clearConsent()
    }

    // MARK: - Logged-in user profile (single active user; latest login wins)

    func saveLoggedInProfile(_ profile: Hcp, role: DocereeUserRole) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: profile, requiringSecureCoding: true)
            defaults.set(role.rawValue, forKey: loggedInUserRoleKey)
            defaults.set(data, forKey: loggedInUserProfileKey)
        } catch {
            DocereeLog.debug("Failed to archive logged-in profile: \(error)")
        }
    }

    func loadLoggedInProfile() -> Hcp? {
        guard let data = defaults.data(forKey: loggedInUserProfileKey) else { return nil }
        let allowedClasses = NSSet(array: [NSString.self, Hcp.self, NSNumber.self])
        do {
            return try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: allowedClasses as! Set<AnyHashable>,
                from: data
            ) as? Hcp
        } catch {
            DocereeLog.debug("Failed to decode logged-in profile: \(error)")
            return nil
        }
    }

    func loggedInUserRole() -> DocereeUserRole? {
        guard let rawValue = defaults.string(forKey: loggedInUserRoleKey) else { return nil }
        return DocereeUserRole.fromStoredRawValue(rawValue)
    }

    func clearLoggedInProfile() {
        defaults.removeObject(forKey: loggedInUserRoleKey)
        defaults.removeObject(forKey: loggedInUserProfileKey)
    }

    func resetLoggedInProfileForTesting() {
        clearLoggedInProfile()
    }
}
