import Foundation

/// Maps stored `actionEvent` objects to the compact key form required by the ad-request `atd` field.
enum ActionAttributesATDMapper {

    static func atdPayload(from events: [[String: Any]]) -> [String: Any] {
        let evts = events.map(shortFormEvent)
        guard !evts.isEmpty else { return [:] }
        return ["evts": evts]
    }

    static func shortFormEvent(_ event: [String: Any]) -> [String: Any] {
        var output: [String: Any] = [:]
        output.reserveCapacity(event.count)

        for (key, value) in event {
            guard let shortKey = resolveEventKey(key) else { continue }
            output[shortKey] = transformEventValue(value, shortKey: shortKey)
        }

        return output
    }

    private static let eventKeys: [String: String] = [
        "type": "typ",
        "timestamp": "ts",
        "appointmentId": "apid",
        "patientId": "ptid",
        "appointmentDate": "adate",
        "appointmentTime": "atime",
        "visitType": "vtyp",
        "hcpId": "npi",
        "hashedHcpId": "hnpi",
        "visitUrgency": "urg",
        "facilityName": "facnm",
        "facilityAddress": "facadd",
        "facilityId": "facid",
        "facilityPhone": "facph",
        "reasonForVisit": "rfv",
        "confirmationCode": "cfcd",
        "notificationChannel": "nchn",
        "previousDate": "pdate",
        "previousTime": "ptime",
        "newDate": "ndate",
        "newTime": "ntime",
        "rescheduleReason": "rrsn",
        "initiatedBy": "init",
        "referralId": "rid",
        "specialization": "spec",
        "referralReason": "rrsn",
        "referringHcpId": "rnpi",
        "referringHashedHcpId": "rhnpi",
        "referredToHcpId": "fnpi",
        "referredToHashedHcpId": "fhnpi",
        "urgencyLevel": "ulvl",
        "diagnosisIcd10": "dicd",
        "authorizationRequired": "areq",
        "authorizationNumber": "anum",
        "expiryDate": "expdt",
        "checkedInAt": "ciat",
        "checkinMethod": "cmth",
        "waitTimeMinutes": "wait",
        "roomAssigned": "room",
        "intakeComplete": "intk",
        "checkoutTimestamp": "cots",
        "visitDurationMinutes": "vdur",
        "billingStatus": "bill",
        "providerNotesStatus": "pnote",
        "followUpInstructions": "finst",
        "referralIssued": "refiss",
        "nextAppointmentScheduled": "nxtapt",
        "nextAppointmentDate": "nadate",
        "nextAppointmentTime": "natime",
        "nextAppointmentFacilityId": "nafacid",
        "nextAppointmentVisitType": "navtyp"
    ]

    private static let reasonForVisitKeys: [String: String] = [
        "chiefComplaint": "cc",
        "symptomDuration": "sdur",
        "symptomSeverity": "ssev",
        "visitContext": "vctx"
    ]

    private static let passthroughEventKeys: Set<String> = [
        "typ", "ts", "apid", "ptid", "adate", "atime", "vtyp", "npi", "hnpi", "urg",
        "facnm", "facadd", "facid", "facph", "rfv", "cfcd", "nchn", "pdate", "ptime",
        "ndate", "ntime", "rrsn", "init", "rid", "spec", "rnpi", "rhnpi", "fnpi", "fhnpi",
        "ulvl", "dicd", "areq", "anum", "expdt", "ciat", "cmth", "wait", "room", "intk",
        "cots", "vdur", "bill", "pnote", "finst", "refiss", "nxtapt", "nadate", "natime",
        "nafacid", "navtyp"
    ]

    private static let passthroughReasonForVisitKeys: Set<String> = [
        "cc", "sdur", "ssev", "vctx"
    ]

    private static func resolveEventKey(_ key: String) -> String? {
        resolveKey(key, map: eventKeys, passthrough: passthroughEventKeys)
    }

    private static func resolveReasonForVisitKey(_ key: String) -> String? {
        resolveKey(key, map: reasonForVisitKeys, passthrough: passthroughReasonForVisitKeys)
    }

    private static func resolveKey(
        _ key: String,
        map: [String: String],
        passthrough: Set<String>
    ) -> String? {
        if let shortKey = map[key] {
            return shortKey
        }
        if map.values.contains(key) || passthrough.contains(key) {
            return key
        }
        return nil
    }

    private static func transformEventValue(_ value: Any, shortKey: String) -> Any {
        if shortKey == "rfv" {
            return transformReasonForVisitArray(asArray(value))
        }
        return value
    }

    private static func transformReasonForVisitArray(_ values: [Any]) -> [Any] {
        values.compactMap { item in
            guard let dictionary = item as? [String: Any] else { return item }
            return transformReasonForVisitItem(dictionary)
        }
    }

    private static func transformReasonForVisitItem(_ dictionary: [String: Any]) -> [String: Any] {
        var output: [String: Any] = [:]
        for (key, value) in dictionary {
            guard let shortKey = resolveReasonForVisitKey(key) else { continue }
            output[shortKey] = value
        }
        return output
    }

    private static func asArray(_ value: Any) -> [Any] {
        value as? [Any] ?? []
    }
}
