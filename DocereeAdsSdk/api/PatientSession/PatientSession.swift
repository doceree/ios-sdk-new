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

            let payloadBuilder = DataAttributesPayloadBuilder()
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

    public func hasActiveSession() -> Bool {
        guard let sessionId = StorageManager.shared.getItem(forKey: "sessionId"),
              !sessionId.isEmpty else {
            return false
        }
        return !StorageManager.shared.isExpired()
    }

    public func savePatientData(_ newValue: JSONObject) -> Bool {
        if let sessionId = StorageManager.shared.getItem(forKey: "sessionId"), !sessionId.isEmpty {
            DocereeLog.debug("sessionId: \(sessionId)")
        }

        if let savedValue = StorageManager.shared.getPatientData() {
            let mergedValue = normalizeActionEvents(in: mergeDictionaries(savedValue, newValue))
            StorageManager.shared.savePatientData(mergedValue)
            return true
        }

        StorageManager.shared.savePatientData(normalizeActionEvents(in: newValue))
        return true
    }

    private func normalizeActionEvents(in payload: [String: Any]) -> [String: Any] {
        guard let events = payload[DataAttributesPayloadBuilder.actionEventKey] as? [[String: Any]],
              !events.isEmpty else {
            return payload
        }

        var normalized = payload
        normalized[DataAttributesPayloadBuilder.actionEventKey] =
            DataAttributesPayloadBuilder.mergeActionEventsByType(existing: events, incoming: [])
        return normalized
    }

    // Function to merge two dictionaries
    func mergeDictionaries(_ dict1: [String: Any], _ dict2: [String: Any]) -> [String: Any] {
        var mergedDict = dict1
        for (key, value) in dict2 {
            if key == DataAttributesPayloadBuilder.actionEventKey {
                let existingEvents = mergedDict[key] as? [[String: Any]] ?? []
                let incomingEvents: [[String: Any]]
                if let events = value as? [[String: Any]] {
                    incomingEvents = events
                } else if let event = value as? [String: Any] {
                    incomingEvents = [event]
                } else {
                    mergedDict[key] = value
                    continue
                }
                mergedDict[key] = DataAttributesPayloadBuilder.mergeActionEventsByType(
                    existing: existingEvents,
                    incoming: incomingEvents
                )
                continue
            }
            if let dictValue = value as? [String: Any], let existingValue = mergedDict[key] as? [String: Any] {
                mergedDict[key] = mergeDictionaries(existingValue, dictValue)
            } else {
                mergedDict[key] = value
            }
        }
        return mergedDict
    }
    func getPtd() -> String {
        guard let stored = StorageManager.shared.getPatientData(),
              let patientDetails = stored[DataAttributesPayloadBuilder.patientDetailsKey] as? [String: Any],
              !patientDetails.isEmpty else {
            return ""
        }
        do {
            return try encodeJSONObjectToBase64(patientDetails)
        } catch {
            DocereeLog.debug("Error fetching patient data for ptd: \(error)")
            return ""
        }
    }

    func getAtd() -> String {
        guard let stored = StorageManager.shared.getPatientData(),
              let actionEvents = stored[DataAttributesPayloadBuilder.actionEventKey] as? [[String: Any]],
              !actionEvents.isEmpty else {
            return ""
        }
        let deduplicated = DataAttributesPayloadBuilder.mergeActionEventsByType(
            existing: actionEvents,
            incoming: []
        )
        guard !deduplicated.isEmpty else {
            return ""
        }
        do {
            return try encodeJSONObjectToBase64(deduplicated)
        } catch {
            DocereeLog.debug("Error fetching action data for atd: \(error)")
            return ""
        }
    }

    func getBr() -> String {
        DocereeLog.debug("Br called")
        guard let payload = sessionPayloadForBr() else {
            DocereeLog.debug("PatientSession: No session data found")
            return ""
        }
        do {
            let encodedBr = try encodeJSONObjectToBase64(payload)
            DocereeLog.debug("Encrypted br: \(encodedBr)")
            return encodedBr
        } catch {
            DocereeLog.debug("Error fetching session data for br: \(error)")
            return ""
        }
    }

    private func sessionPayloadForBr() -> [String: Any]? {
        guard let stored = StorageManager.shared.getPatientData() else {
            return nil
        }

        var payload: [String: Any] = [:]
        if let sessionDetails = stored[DataAttributesPayloadBuilder.sessionDetailsKey] as? [String: Any],
           !sessionDetails.isEmpty {
            payload = sessionDetails
        }

        if let sessionId = stored[PatientData.shared.sessionId] as? String, !sessionId.isEmpty {
            payload[PatientData.shared.sessionId] = sessionId
        }

        return payload.isEmpty ? nil : payload
    }

    private func encodeJSONObjectToBase64(_ object: Any) throws -> String {
        var jsonString = String(data: try JSONSerialization.data(withJSONObject: object, options: []), encoding: .utf8)!
        jsonString = jsonString.replacingOccurrences(of: "\\/", with: "/")
        return try Utils().encodeBase64(jsonString)
    }
}

extension PatientSession: @unchecked Sendable {}

