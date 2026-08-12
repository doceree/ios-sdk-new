import Foundation

/// Maps stored `patientDetails` objects to the compact key form required by the ad-request `ptd` field.
enum PatientDetailsPTDMapper {

    static func shortForm(_ details: [String: Any]) -> [String: Any] {
        transformDictionary(details, context: .root)
    }

    private enum Context {
        case root
        case consent
        case insurance
        case clinicalProfile
        case pharmacy
        case allergy
        case medication
        case surgery
        case familyHistory
        case socialHistory
    }

    private static let rootKeys: [String: String] = [
        "patientId": "pid",
        "hashedId": "hpid",
        "name": "pname",
        "dob": "pdob",
        "mobile": "mob",
        "email": "eml",
        "country": "cntry",
        "hashedMobile": "hmob",
        "hashedEmail": "heml",
        "zipCode": "zip",
        "gender": "gd",
        "age": "ag",
        "hashedSsn": "hssn",
        "consent": "cns",
        "insurance": "ins",
        "clinicalProfile": "cp"
    ]

    private static let consentKeys: [String: String] = [
        "consentBasis": "bas",
        "mechanism": "mech",
        "grantedAt": "gat",
        "expiresAt": "eat",
        "consentReferenceId": "crid"
    ]

    private static let insuranceKeys: [String: String] = [
        "hasInsurance": "has",
        "insuranceType": "typ",
        "insuranceName": "nm",
        "insurancePlanName": "pnm",
        "insurancePlanId": "pid",
        "insuranceGroupId": "gid",
        "insuranceBin": "bin",
        "insurancePcn": "pcn",
        "insuranceMemberId": "mid",
        "policyholderName": "phnm",
        "policyholderDob": "phdob",
        "relationshipToPolicyholder": "rel",
        "primaryPayerPhone": "pph"
    ]

    private static let clinicalProfileKeys: [String: String] = [
        "smokingStatus": "smk",
        "preferredPharmacy": "pph",
        "newAllergies": "nalrg",
        "newMedications": "nmed",
        "surgicalHistory": "surg",
        "familyHistory": "famh",
        "socialHistory": "soc"
    ]

    private static let pharmacyKeys: [String: String] = [
        "idType": "idt",
        "name": "nm"
    ]

    private static let allergyKeys: [String: String] = [
        "allergen": "algn",
        "allergenType": "atyp",
        "reaction": "rxn",
        "severity": "sev",
        "onsetDate": "odt",
        "status": "sts"
    ]

    private static let medicationKeys: [String: String] = [
        "rxType": "rxt",
        "rxCode": "rxc",
        "medicationName": "mnm",
        "dosage": "dos",
        "frequency": "frq",
        "startDate": "sdt",
        "endDate": "edt",
        "status": "sts"
    ]

    private static let surgeryKeys: [String: String] = [
        "procedureName": "prnm",
        "procedureCode": "prcd",
        "procedureDate": "prdt",
        "procedureType": "prtp"
    ]

    private static let familyHistoryKeys: [String: String] = [
        "conditionName": "cdnm",
        "conditionCode": "cdcd",
        "relation": "rel",
        "genetic": "gen"
    ]

    private static let socialHistoryKeys: [String: String] = [
        "tobaccoUse": "tob",
        "alcoholUse": "alc",
        "substanceUse": "subs",
        "physicalActivity": "phy"
    ]

    private static let passthroughRootKeys: Set<String> = [
        "pid", "hpid", "pname", "pdob", "mob", "eml", "cntry", "city", "hmob", "heml",
        "state", "zip", "gd", "ag", "ssn", "hssn", "cns", "ins", "cp"
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
        case .consent:
            return Set(consentKeys.values).union(["bas", "mech", "gat", "eat", "crid"])
        case .insurance:
            return Set(insuranceKeys.values).union(["has", "typ", "nm", "pnm", "pid", "gid", "bin", "pcn", "mid", "phnm", "phdob", "rel", "pph"])
        case .clinicalProfile:
            return Set(clinicalProfileKeys.values).union(["smk", "pph", "nalrg", "nmed", "surg", "famh", "soc"])
        case .pharmacy:
            return Set(pharmacyKeys.values).union(["idt", "id", "nm"])
        case .allergy:
            return Set(allergyKeys.values).union(["algn", "atyp", "rxn", "sev", "odt", "sts"])
        case .medication:
            return Set(medicationKeys.values).union(["rxt", "rxc", "mnm", "dos", "frq", "sdt", "edt", "sts"])
        case .surgery:
            return Set(surgeryKeys.values).union(["prnm", "prcd", "prdt", "prtp"])
        case .familyHistory:
            return Set(familyHistoryKeys.values).union(["cdnm", "cdcd", "rel", "gen"])
        case .socialHistory:
            return Set(socialHistoryKeys.values).union(["tob", "alc", "subs", "phy"])
        }
    }

    private static func keyMap(for context: Context) -> [String: String] {
        switch context {
        case .root:
            return rootKeys
        case .consent:
            return consentKeys
        case .insurance:
            return insuranceKeys
        case .clinicalProfile:
            return clinicalProfileKeys
        case .pharmacy:
            return pharmacyKeys
        case .allergy:
            return allergyKeys
        case .medication:
            return medicationKeys
        case .surgery:
            return surgeryKeys
        case .familyHistory:
            return familyHistoryKeys
        case .socialHistory:
            return socialHistoryKeys
        }
    }

    private static func transformValue(_ value: Any, shortKey: String, context: Context) -> Any {
        switch context {
        case .root:
            switch shortKey {
            case "cns":
                return transformDictionary(asDictionary(value), context: .consent)
            case "ins":
                return transformDictionary(asDictionary(value), context: .insurance)
            case "cp":
                return transformClinicalProfile(asDictionary(value))
            default:
                return value
            }
        case .clinicalProfile:
            switch shortKey {
            case "pph":
                return transformDictionary(asDictionary(value), context: .pharmacy)
            case "nalrg":
                return transformArray(asArray(value), itemContext: .allergy)
            case "nmed":
                return transformArray(asArray(value), itemContext: .medication)
            case "surg":
                return transformArray(asArray(value), itemContext: .surgery)
            case "famh":
                return transformArray(asArray(value), itemContext: .familyHistory)
            case "soc":
                return transformDictionary(asDictionary(value), context: .socialHistory)
            default:
                return value
            }
        default:
            return value
        }
    }

    private static func transformClinicalProfile(_ dictionary: [String: Any]) -> [String: Any] {
        var output: [String: Any] = [:]
        output.reserveCapacity(dictionary.count)

        for (key, value) in dictionary {
            guard let shortKey = resolveShortKey(key, context: .clinicalProfile) else { continue }
            output[shortKey] = transformValue(value, shortKey: shortKey, context: .clinicalProfile)
        }

        return output
    }

    private static func transformArray(_ values: [Any], itemContext: Context) -> [Any] {
        values.compactMap { item in
            guard let dictionary = item as? [String: Any] else { return item }
            return transformDictionary(dictionary, context: itemContext)
        }
    }

    private static func asDictionary(_ value: Any) -> [String: Any] {
        value as? [String: Any] ?? [:]
    }

    private static func asArray(_ value: Any) -> [Any] {
        value as? [Any] ?? []
    }
}
