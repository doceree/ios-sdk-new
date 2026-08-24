//
//  StorageManager.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 30/05/24.
//

import Foundation


class StorageManager {
    
    /// Must match `PatientSession` window: `TimeInterval` is always **seconds** (not milliseconds).
    private let expirationTime: TimeInterval = 30 * 60
    private let timestampKey = "timestamp"
    private let patientKey = "patientData"
    typealias JSONObject = [String: Any]
    static let shared = StorageManager()
    
    private init() {}
    
    func clearAllAttributeAndSessionData() {
        UserDefaults.standard.removeObject(forKey: patientKey)
        UserDefaults.standard.removeObject(forKey: timestampKey)
        UserDefaults.standard.removeObject(forKey: "sessionId")
    }
    
    func clearUserDefaults() {
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            DocereeLog.debug("Cleared")
        }
    }
    
    func clearItem(forKey key: String) async {
        UserDefaults.standard.removeObject(forKey: key)
        DocereeLog.debug("Cleared Item \(key)")
    }
    
    func saveItem(forKey key: String, value: String) async {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func getItem(forKey key: String) -> String? {
        if let savedString = UserDefaults.standard.string(forKey: key) {
            DocereeLog.debug("Retrieved string: \(savedString)")
            return savedString
        } else {
            DocereeLog.debug("No string found for key \(key)")
            return nil
        }
    }
    
    func saveData(forKey key: String, value: JSONObject) {
        UserDefaults.standard.set(value, forKey: key)
        DocereeLog.debug("Data stored successfully")
    }
    
    func getData(forKey key: String) -> JSONObject? {
        if let savedData = UserDefaults.standard.object(forKey: key) as? [String: Any] {
            return savedData
        } else {
            DocereeLog.debug("No data found for key 'userProfile'")
        }
        return nil
    }
    
    func saveTimestamp() async {
        let currentTime = Date().timeIntervalSince1970
        UserDefaults.standard.set(currentTime, forKey: timestampKey)
        DocereeLog.debug("Timestamp saved successfully")
    }
    
    func isExpired() -> Bool {
        if let timestamp = UserDefaults.standard.value(forKey: timestampKey) as? TimeInterval {
            let currentTime = Date().timeIntervalSince1970
            let timeDifference = currentTime - timestamp
            if timeDifference <= expirationTime {
                return false
            } else {
                // If data has expired, remove it from UserDefaults and return true
                UserDefaults.standard.removeObject(forKey: timestampKey)
                return true
            }
        } else {
            return true
        }
    }
    
    func savePatientData(_ value: JSONObject) {
        if hasSessionTimestamp(), isExpired() {
            DocereeLog.debug("savePatientData session expired!")
            UserDefaults.standard.removeObject(forKey: patientKey)
            return
        }
        saveData(forKey: patientKey, value: value)
    }
    
    func getPatientData() -> JSONObject? {
        if hasSessionTimestamp(), isExpired() {
            DocereeLog.debug("getPatientData session expired!")
            UserDefaults.standard.removeObject(forKey: patientKey)
            return nil
        }
        return getData(forKey: patientKey)
    }

    private func hasSessionTimestamp() -> Bool {
        UserDefaults.standard.value(forKey: timestampKey) != nil
    }
}

