//
//  StorageManager.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 30/05/24.
//

import Foundation


class StorageManager {
    
    private let expirationTime: TimeInterval = 3 * 60 * 1000 // 3 minutes in milliseconds
    private let timestampKey = "timestamp"
    private let patientKey = "patientData"
    typealias JSONObject = [String: Any]
    static let shared = StorageManager()
    
    private init() {}
    
    func clearUserDefaults() {
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            print("Cleared")
        }
    }
    
    func clearItem(forKey key: String) async {
        UserDefaults.standard.removeObject(forKey: key)
        print("Cleared Item ", key)
    }
    
    func saveItem(forKey key: String, value: String) async {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func getItem(forKey key: String) -> String? {
        if let savedString = UserDefaults.standard.string(forKey: key) {
            print("Retrieved string: \(savedString)")
            return savedString
        } else {
            print("No string found for key \(key)")
            return nil
        }
    }
    
    func saveData(forKey key: String, value: JSONObject) {
        UserDefaults.standard.set(value, forKey: key)
        print("Data stored successfully")
    }
    
    func getData(forKey key: String) -> JSONObject? {
        if let savedData = UserDefaults.standard.object(forKey: key) as? [String: Any] {
            return savedData
        } else {
            print("No data found for key 'userProfile'")
        }
        return nil
    }
    
    func saveTimestamp() async {
        let currentTime = Date().timeIntervalSince1970
        UserDefaults.standard.set(currentTime, forKey: timestampKey)
        print("Timestamp saved successfully")
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
        let expired = isExpired()
        if expired {
            print("savePatientData session expired!")
            UserDefaults.standard.removeObject(forKey: patientKey)
            return
        }
        saveData(forKey: patientKey, value: value)
    }
    
    func getPatientData() -> JSONObject? {
        let expired = isExpired()
        if expired {
            print("getPatientData session expired!")
            UserDefaults.standard.removeObject(forKey: patientKey)
            return nil
        }
        return getData(forKey: patientKey)
    }
}

