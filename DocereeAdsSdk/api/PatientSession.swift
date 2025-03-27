//
//  PatientSession.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 30/05/24.
//

import Foundation

public class PatientSession {
    static var sessionId: String?
    private let expirationTime: TimeInterval = 3 * 60 // 3 minutes in seconds
    public typealias JSONObject = [String: Any]
    
    public init() {}
    
    public func startSession() async {
        do {
            // Save timestamp
            await StorageManager.shared.saveTimestamp()
            print("sessionId:", PatientSession.sessionId ?? "nil")

            // End session if sessionId exists
            if PatientSession.sessionId != nil {
                await endSession()
            }

            // Generate new sessionId
            PatientSession.sessionId = try await Utils().sessionId()
            print("Generated sessionId:", PatientSession.sessionId ?? "nil")

            // Call PatientSessionApi
            try await PatientSessionApi.send(sessionId: PatientSession.sessionId!, status: 1)

            // Save sessionId
            await StorageManager.shared.saveItem(forKey: "sessionId", value: PatientSession.sessionId!)

            // Build patient object
            let patientBuilder = PatientBuilder()
                .add(key: "sessionId", value: PatientSession.sessionId!)
            let patient = patientBuilder.build()

            // Save patient data
//            if let patient = patient {
            _ = savePatientData(patient.toJson())
//            }

            // Schedule endSession after expiration time
            DispatchQueue.main.asyncAfter(deadline: .now() + expirationTime) {
                Task {
                    await self.endSession()
                }
            }
        } catch {
            print("Error in startSession:", error)
        }
    }

    public func endSession() async {
        print("endSession")
        do {
            if let sessionId = StorageManager.shared.getItem(forKey: "sessionId") {
                print("sessionId:", sessionId)
                try await PatientSessionApi.send(sessionId: sessionId, status: 0)
                await StorageManager.shared.clearItem(forKey: "patientData")
                await StorageManager.shared.clearItem(forKey: "sessionId")
                PatientSession.sessionId = nil
            }
        } catch {
            print("Error in endSession:", error)
        }
    }

    public func savePatientData(_ newValue: JSONObject) -> Bool {
        if let sessionId = StorageManager.shared.getItem(forKey: "sessionId") {
            print("sessionId:", sessionId)
            if sessionId.isEmpty {
                print("No session found!")
                return false
            }

            if let savedValue = StorageManager.shared.getPatientData() {
                let mergedValue = mergeDictionaries(savedValue, newValue)
                StorageManager.shared.savePatientData(mergedValue)
                return true
            } else {
                StorageManager.shared.savePatientData(newValue)
                return true
            }
        }
        return false
    }
    // Function to merge two dictionaries
    func mergeDictionaries(_ dict1: [String: Any], _ dict2: [String: Any]) -> [String: Any] {
        var mergedDict = dict1
        for (key, value) in dict2 {
            if let dictValue = value as? [String: Any], let existingValue = mergedDict[key] as? [String: Any] {
                mergedDict[key] = mergeDictionaries(existingValue, dictValue)
            } else {
                mergedDict[key] = value
            }
        }
        return mergedDict
    }
    func mergeObjects(_ obj1: JSONObject, _ obj2: JSONObject) -> JSONObject {
        // Assuming Patient is a struct or class with properties to be merged
        let merged = obj1
        // Merge obj2 properties into obj1 (implement the merging logic as per your requirements)
        return merged
    }

    func getBr() -> String {
        print("Br called")
        do {
            if let patient = StorageManager.shared.getPatientData() {
                let attributes = ["attributes": patient]
                var jsonString = String(data: try JSONSerialization.data(withJSONObject: attributes, options: []), encoding: .utf8)!
                // Replace escaped characters manually
                jsonString = jsonString.replacingOccurrences(of: "\\/", with: "/")
                let encodedBr = try Utils().encodeBase64(jsonString)
                print("Encrypted br:", encodedBr)
                return encodedBr
            } else {
                print("PatientSession: No patient found")
            }
        } catch {
            print("Error fetching patient data:", error)
        }
        return ""
    }
}

