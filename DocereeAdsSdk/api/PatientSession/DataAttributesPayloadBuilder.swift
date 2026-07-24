//
//  DataAttributesPayloadBuilder.swift
//  DocereeAdsSdk
//

import Foundation

public struct DataAttributesPayload {
    var sessionId: String
    var extraAttributes: [String: Any]

    public func toJson() -> [String: Any] {
        var map: [String: Any?] = [
            PatientData.shared.sessionId: sessionId
        ]
        for (key, value) in extraAttributes {
            map[key] = value
        }
        map = filterEmptyValues(from: map)
        var nonOptionalMap: [String: Any] = [:]
        for (key, value) in map {
            nonOptionalMap[key] = value
        }
        DocereeLog.debug("\(nonOptionalMap)")
        return nonOptionalMap
    }

    func filterEmptyValues(from map: [String: Any?]) -> [String: Any?] {
        return map.filter { (_, value) in
            if value == nil {
                return false
            }
            if let stringValue = value as? String, stringValue.isEmpty {
                return false
            }
            if let arrayValue = value as? [Any], arrayValue.isEmpty {
                return false
            }
            if let dictValue = value as? [String: Any], dictValue.isEmpty {
                return false
            }
            return true
        }
    }
}

public class DataAttributesPayloadBuilder {
    /// HCP / user context object for `docereeAds.add`.
    public static let userDetailsKey = "userDetails"
    /// Patient identity and clinical profile object for `docereeAds.add`.
    public static let patientDetailsKey = "patientDetails"
    /// Care-team associate object for `docereeAds.add`.
    public static let healthAssociateKey = "healthAssociate"
    /// Appointment / workflow events; each `add` appends one validated event object into an array.
    public static let actionEventKey = "actionEvent"
    /// Session-scoped attributes (vitals, `diagnosis_v1`, etc.) as one nested JSON object.
    public static let sessionDetailsKey = "sessionDetails"

    private var payload: DataAttributesPayload

    public init() {
        self.payload = DataAttributesPayload(sessionId: "", extraAttributes: [:])
    }

    public func add(key: String, value: Any) -> DataAttributesPayloadBuilder {
        if key == "sessionId" {
            payload.sessionId = value as? String ?? ""
            return self
        }
        addStandardizedAttribute(key: key, value: value)
        return self
    }

    /// Maps legacy flat `add(key:value:)` inputs to `PatientData` short keys. Session-scoped fields use `sessionDetails` instead.
    private static let standardizedAliases: [String: String] = [
        "age": "ag",
        "gender": "gd",
        "insurance": "ins",
        "insuranceType": "instyp",
        "insuranceName": "insnm",
        "bp": "bp",
        "pulse": "ps",
        "respiration": "rr",
        "labTest": "lt",
        "diagnosis": "dx",
        "prescription": "rx",
        "pharmacy": "ph",
        "labTestHistory": "lth",
        "diagnosisHistory": "dxh",
        "prescriptionHistory": "rxh",
        "pharmacyHistory": "phh"
    ]

    private static let appointmentActionTypes: Set<String> = [
        "appt_request",
        "patient_checked_in",
        "appt_confirmed",
        "checkout",
        "patient_checked_out",
        "appt_rescheduled",
        "referral"
    ]

    private static let appointmentRequiredFields: [String] = [
        "type",
        "timestamp",
        "patientId",
        "appointmentId"
    ]

    private func addStandardizedAttribute(key: String, value: Any) {
        let resolvedKey = Self.standardizedAliases[key] ?? key

        if resolvedKey == Self.actionEventKey {
            guard let event = value as? [String: Any], isValidActionEvent(event) else {
                DocereeLog.debug("DataAttributesPayloadBuilder: dropping invalid actionEvent payload")
                return
            }
            if var events = payload.extraAttributes[resolvedKey] as? [[String: Any]] {
                events.append(event)
                payload.extraAttributes[resolvedKey] = events
            } else {
                payload.extraAttributes[resolvedKey] = [event]
            }
            return
        }

        if let existing = payload.extraAttributes[resolvedKey] {
            payload.extraAttributes[resolvedKey] = mergeAttributeValues(existing: existing, incoming: value)
        } else {
            payload.extraAttributes[resolvedKey] = value
        }
    }

    private func isValidActionEvent(_ event: [String: Any]) -> Bool {
        guard let actionType = event["type"] as? String, !actionType.isEmpty else {
            return false
        }
        guard Self.appointmentActionTypes.contains(actionType) else {
            return true
        }
        for key in Self.appointmentRequiredFields {
            guard let value = event[key] else {
                return false
            }
            if let stringValue = value as? String, stringValue.isEmpty {
                return false
            }
        }
        return true
    }

    private func mergeAttributeValues(existing: Any, incoming: Any) -> Any {
        if let existingDict = existing as? [String: Any], let incomingDict = incoming as? [String: Any] {
            return mergeNestedDictionaries(existingDict, incomingDict)
        }
        if var existingArray = existing as? [[String: Any]],
           let incomingArray = incoming as? [[String: Any]] {
            existingArray.append(contentsOf: incomingArray)
            return existingArray
        }
        if var existingArray = existing as? [Any], let incomingArray = incoming as? [Any] {
            existingArray.append(contentsOf: incomingArray)
            return existingArray
        }
        return incoming
    }

    private func mergeNestedDictionaries(_ dict1: [String: Any], _ dict2: [String: Any]) -> [String: Any] {
        var merged = dict1
        for (key, value) in dict2 {
            if let dictValue = value as? [String: Any], let existingValue = merged[key] as? [String: Any] {
                merged[key] = mergeNestedDictionaries(existingValue, dictValue)
            } else {
                merged[key] = value
            }
        }
        return merged
    }

    public func build() -> DataAttributesPayload {
        return payload
    }
}

@available(*, deprecated, renamed: "DataAttributesPayload")
public typealias SessionPayload = DataAttributesPayload

@available(*, deprecated, renamed: "DataAttributesPayloadBuilder")
public typealias SessionPayloadBuilder = DataAttributesPayloadBuilder
