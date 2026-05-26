//
//  PatientSession.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 30/05/24.
//

import Foundation

public class PatientSession {
    static var sessionId: String?
    private let expirationTime: TimeInterval = 30 * 60 // 30 minutes in seconds
    public typealias JSONObject = [String: Any]
    
    public init() {}
    
    public func startSession() async {
        do {
            // Save timestamp
            await StorageManager.shared.saveTimestamp()
            DocereeLog.debug("sessionId: \(PatientSession.sessionId ?? "nil")")

            // End session if sessionId exists
            if PatientSession.sessionId != nil {
                await endSession()
            }

            // Generate new sessionId
            PatientSession.sessionId = try await Utils().sessionId()
            DocereeLog.debug("Generated sessionId: \(PatientSession.sessionId ?? "nil")")

            // Call PatientSessionApi
            try await PatientSessionApi.send(sessionId: PatientSession.sessionId!, status: 1)

            // Save sessionId
            await StorageManager.shared.saveItem(forKey: "sessionId", value: PatientSession.sessionId!)

            let payloadBuilder = SessionPayloadBuilder()
                .add(key: "sessionId", value: PatientSession.sessionId!)
            let payload = payloadBuilder.build()

            _ = savePatientData(payload.toJson())

            // Schedule endSession after expiration time
            let patientSession = PatientSession()
            DispatchQueue.main.asyncAfter(deadline: .now() + expirationTime) {
                Task {
                    await patientSession.endSession()
                }
            }
        } catch {
            DocereeLog.debug("Error in startSession: \(error)")
        }
    }

    public func endSession() async {
        DocereeLog.debug("endSession")
        do {
            if let sessionId = StorageManager.shared.getItem(forKey: "sessionId") {
                DocereeLog.debug("sessionId: \(sessionId)")
                try await PatientSessionApi.send(sessionId: sessionId, status: 0)
                await StorageManager.shared.clearItem(forKey: "patientData")
                await StorageManager.shared.clearItem(forKey: "sessionId")
                PatientSession.sessionId = nil
            }
        } catch {
            DocereeLog.debug("Error in endSession: \(error)")
        }
    }

    public func savePatientData(_ newValue: JSONObject) -> Bool {
        if let sessionId = StorageManager.shared.getItem(forKey: "sessionId") {
            DocereeLog.debug("sessionId: \(sessionId)")
            if sessionId.isEmpty {
                DocereeLog.debug("No session found!")
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
    func getBr() -> String {
        DocereeLog.debug("Br called")
        do {
            if let patient = StorageManager.shared.getPatientData() {
                let attributes = ["attributes": patient]
                var jsonString = String(data: try JSONSerialization.data(withJSONObject: attributes, options: []), encoding: .utf8)!
                // Replace escaped characters manually
                jsonString = jsonString.replacingOccurrences(of: "\\/", with: "/")
                let encodedBr = try Utils().encodeBase64(jsonString)
                DocereeLog.debug("Encrypted br: \(encodedBr)")
                return encodedBr
            } else {
                DocereeLog.debug("PatientSession: No patient found")
            }
        } catch {
            DocereeLog.debug("Error fetching patient data: \(error)")
        }
        return ""
    }
}

extension PatientSession: @unchecked Sendable {}

