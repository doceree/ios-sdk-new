import Foundation

/// Maps stored `sessionDetails` objects to the compact key form required by the ad-request `br` field.
enum SessionAttributesBRMapper {

    static func brPayload(from sessionDetails: [String: Any]) -> [String: Any] {
        let attributes = shortForm(sessionDetails)
        guard !attributes.isEmpty else { return [:] }
        return ["attributes": attributes]
    }

    static func shortForm(_ details: [String: Any]) -> [String: Any] {
        transformDictionary(details, context: .root)
    }

    private enum Context {
        case root
        case diagnosis
        case labTest
        case prescription
        case pharmacyFill
        case fill
        case labTestHistory
        case diagnosisHistory
        case prescriptionHistory
    }

    private static let rootKeys: [String: String] = [
        "sessionId": "sid",
        "temperature": "tm",
        "bloodPressureSystolic": "bps",
        "bloodPressureDiastolic": "bpd",
        "heartRate": "hr",
        "oxygenSaturation": "spo2",
        "respiratoryRate": "rrate",
        "height": "ht",
        "weight": "wt",
        "vitalsRecordedAt": "rat",
        "pharmacy": "ph",
        "diagnosis_v1": "dx_v1",
        "labtest_v1": "lt_v1",
        "prescription_v1": "rx_v1",
        "labtesthistory_v1": "lth_v1",
        "diagnosishistory_v1": "dxh_v1",
        "prescriptionhistory_v1": "rxh_v1",
        "pharmacyFillHistory": "phh_v1",
        "pharmacynotes_v1": "pn_v1"
    ]

    private static let diagnosisKeys: [String: String] = [
        "dxCode": "dxc",
        "status": "sts"
    ]

    private static let labTestKeys: [String: String] = [
        "hcpcsCode": "hcc",
        "testName": "tnm",
        "resultStatus": "rsts",
        "resultValue": "rval",
        "resultUnit": "runt"
    ]

    private static let prescriptionKeys: [String: String] = [
        "rxCode": "rxc",
        "quantity": "qty",
        "daysSupply": "ds",
        "refillsRemaining": "rr",
        "status": "sts"
    ]

    private static let pharmacyFillKeys: [String: String] = [
        "dispensedDate": "ddt",
        "pharmacyName": "phnm",
        "ncpdpId": "ncid",
        "pharmacyNpi": "pnpi",
        "fills": "fls"
    ]

    private static let fillKeys: [String: String] = [
        "quantity": "qty",
        "daysSupply": "ds",
        "fillNumber": "fno"
    ]

    private static let labTestHistoryKeys: [String: String] = [
        "performedDate": "pdt",
        "orderDate": "odt",
        "orderedByHcpId": "ohid",
        "orderedByHashedHcpId": "ohhid",
        "tests": "tsts"
    ]

    private static let diagnosisHistoryKeys: [String: String] = [
        "encounterDate": "edt",
        "dxType": "dxt",
        "diagnosedByHcpId": "dhid",
        "diagnosedByHashedHcpId": "dhhid",
        "encounterType": "etyp",
        "diagnoses": "dxs"
    ]

    private static let prescriptionHistoryKeys: [String: String] = [
        "prescribedDate": "pdt",
        "rxType": "rxt",
        "prescribedByHcpId": "phid",
        "prescribedByHashedHcpId": "phhid",
        "prescriptions": "rxs"
    ]

    private static let passthroughRootKeys: Set<String> = [
        "sid", "tm", "bps", "bpd", "hr", "spo2", "rrate", "ht", "wt", "bmi", "rat", "ph",
        "phh_v1", "dx_v1", "lt_v1", "rx_v1", "lth_v1", "dxh_v1", "rxh_v1", "pn_v1", "daw_v1"
    ]

    private static func transformDictionary(_ dictionary: [String: Any], context: Context) -> [String: Any] {
        var output: [String: Any] = [:]
        output.reserveCapacity(dictionary.count)

        for (key, value) in dictionary {
            guard let shortKey = resolveShortKey(key, context: context) else { continue }
            output[shortKey] = transformValue(value, shortKey: shortKey, context: context)
        }

        return output
    }

    private static func resolveShortKey(_ key: String, context: Context) -> String? {
        let map = keyMap(for: context)
        if let shortKey = map[key] {
            return shortKey
        }
        if map.values.contains(key) || passthroughKeys(for: context).contains(key) {
            return key
        }
        return nil
    }

    private static func passthroughKeys(for context: Context) -> Set<String> {
        switch context {
        case .root:
            return passthroughRootKeys
        case .diagnosis:
            return Set(diagnosisKeys.values).union(["dxc", "sts"])
        case .labTest:
            return Set(labTestKeys.values).union(["hcc", "tnm", "rsts", "rval", "runt"])
        case .prescription:
            return Set(prescriptionKeys.values).union(["rxc", "qty", "ds", "rr", "sts"])
        case .pharmacyFill:
            return Set(pharmacyFillKeys.values).union(["ddt", "phnm", "ncid", "pnpi", "fls"])
        case .fill:
            return Set(fillKeys.values).union(["ndc", "qty", "ds", "fno"])
        case .labTestHistory:
            return Set(labTestHistoryKeys.values).union(["pdt", "odt", "ohid", "ohhid", "tsts"])
        case .diagnosisHistory:
            return Set(diagnosisHistoryKeys.values).union(["edt", "dxt", "dhid", "dhhid", "etyp", "dxs"])
        case .prescriptionHistory:
            return Set(prescriptionHistoryKeys.values).union(["pdt", "rxt", "phid", "phhid", "rxs"])
        }
    }

    private static func keyMap(for context: Context) -> [String: String] {
        switch context {
        case .root:
            return rootKeys
        case .diagnosis:
            return diagnosisKeys
        case .labTest:
            return labTestKeys
        case .prescription:
            return prescriptionKeys
        case .pharmacyFill:
            return pharmacyFillKeys
        case .fill:
            return fillKeys
        case .labTestHistory:
            return labTestHistoryKeys
        case .diagnosisHistory:
            return diagnosisHistoryKeys
        case .prescriptionHistory:
            return prescriptionHistoryKeys
        }
    }

    private static func transformValue(_ value: Any, shortKey: String, context: Context) -> Any {
        guard context == .root else { return value }

        switch shortKey {
        case "dx_v1":
            return transformArray(asArray(value), itemContext: .diagnosis)
        case "lt_v1", "tsts":
            return transformArray(asArray(value), itemContext: .labTest)
        case "rx_v1", "rxs":
            return transformArray(asArray(value), itemContext: .prescription)
        case "phh_v1":
            return transformArray(asArray(value), itemContext: .pharmacyFill)
        case "lth_v1":
            return transformArray(asArray(value), itemContext: .labTestHistory)
        case "dxh_v1":
            return transformArray(asArray(value), itemContext: .diagnosisHistory)
        case "rxh_v1":
            return transformArray(asArray(value), itemContext: .prescriptionHistory)
        default:
            return value
        }
    }

    private static func transformArray(_ values: [Any], itemContext: Context) -> [Any] {
        values.map { item in
            guard let dictionary = item as? [String: Any] else { return item }
            let mapped = transformDictionary(dictionary, context: itemContext)
            return transformNestedCollections(in: mapped, context: itemContext)
        }
    }

    private static func transformNestedCollections(in dictionary: [String: Any], context: Context) -> [String: Any] {
        var output = dictionary

        switch context {
        case .pharmacyFill:
            if let fills = output["fls"] {
                output["fls"] = transformArray(asArray(fills), itemContext: .fill)
            }
        case .labTestHistory:
            if let tests = output["tsts"] {
                output["tsts"] = transformArray(asArray(tests), itemContext: .labTest)
            }
        case .diagnosisHistory:
            if let diagnoses = output["dxs"] {
                output["dxs"] = transformArray(asArray(diagnoses), itemContext: .diagnosis)
            }
        case .prescriptionHistory:
            if let prescriptions = output["rxs"] {
                output["rxs"] = transformArray(asArray(prescriptions), itemContext: .prescription)
            }
        default:
            break
        }

        return output
    }

    private static func asArray(_ value: Any) -> [Any] {
        value as? [Any] ?? []
    }
}
