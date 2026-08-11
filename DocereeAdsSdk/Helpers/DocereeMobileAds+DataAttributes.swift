import Foundation

extension DocereeMobileAds {

    public static let patientDetailsKey = "patientDetails"
    public static let sessionDetailsKey = "sessionDetails"
    public static let actionEventKey = "actionEvent"
    public static let userDetailsKey = "userDetails"
    public static let healthAssociateKey = "healthAssociate"

    /// Persists a data-attribute key/value pair.
    ///
    /// This is the supported public API for data attributes. New keys can be added without SDK changes.
    @discardableResult
    public func add(_ key: String, value: Any) -> Bool {
        _ = DataAttributesPayloadBuilder().add(key: key, value: value)
        return true
    }

    /// Starts a patient session.
    public func startSession() {
        Task {
            await PatientSession().startSession()
        }
    }

    /// Returns data attributes currently stored by the SDK.
    public func storedDataAttributes() -> [String: Any] {
        StorageManager.shared.getPatientData() ?? [:]
    }

    /// Ends the active patient session and clears stored session attributes.
    public func closeSession() {
        Task {
            await PatientSession().endSession()
        }
    }
}
