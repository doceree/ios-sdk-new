//
//  PatientBuilder.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 30/05/24.
//

import Foundation

// Define a struct for creating Patient objects
public struct Patient {
    var sessionId: String
    var age: String
    var gender: String
    var prescription: [String]
    var labTest: [String]
    var diagnosis: [String]
    var pharmacy: [String]
    var prescriptionHistory: [[String: Any]]
    var labTestHistory: [[String: Any]]
    var diagnosisHistory: [[String: Any]]
    var pharmacyHistory: [[String: Any]]
    var temperature: [String: Any]
    var bp: String
    var pulse: String
    var respiration: String
    var insurance: String
    var insuranceType: [String]
    var insuranceName: [String]
    
    public func toJson() -> [String: Any] {
        var map: [String: Any?] = [
            PatientData.shared.sessionId: sessionId,
            PatientData.shared.age: age,
            PatientData.shared.gender: gender,
            PatientData.shared.insurance: insurance,
            PatientData.shared.insuranceType: insuranceType,
            PatientData.shared.insuranceName: insuranceName,
            PatientData.shared.temperature: temperature,
            PatientData.shared.bp: bp,
            PatientData.shared.pulse: pulse,
            PatientData.shared.respiration: respiration,
            PatientData.shared.labTest: labTest,
            PatientData.shared.diagnosis: diagnosis,
            PatientData.shared.prescription: prescription,
            PatientData.shared.pharmacy: pharmacy,
            PatientData.shared.labTestHistory: labTestHistory,
            PatientData.shared.diagnosisHistory: diagnosisHistory,
            PatientData.shared.prescriptionHistory: prescriptionHistory,
            PatientData.shared.pharmacyHistory: pharmacyHistory
        ]
        
        // Remove keys with nil, empty string, or empty collection values
        map = filterEmptyValues(from: map)
        
        // Convert to [String: Any]
        var nonOptionalMap: [String: Any] = [:]
        for (key, value) in map {
            nonOptionalMap[key] = value
        }
        
        print(nonOptionalMap)
        return nonOptionalMap
    }
    
    func filterEmptyValues(from map: [String: Any?]) -> [String: Any?] {
        return map.filter { (_, value) in
            // Check for nil values
            if value == nil {
                return false
            }
            
            // Check for empty strings
            if let stringValue = value as? String, stringValue.isEmpty {
                return false
            }
            
            // Check for empty arrays
            if let arrayValue = value as? [Any], arrayValue.isEmpty {
                return false
            }
            
            // Check for empty dictionaries
            if let dictValue = value as? [String: Any], dictValue.isEmpty {
                return false
            }
            
            // If none of the above conditions match, keep the value
            return true
        }
    }

}

// Define a Builder class for creating Patient objects
public class PatientBuilder {
    private var patient: Patient

    public init() {
        self.patient = Patient(
            sessionId: "",
            age: "",
            gender: "",
            prescription: [],
            labTest: [],
            diagnosis: [],
            pharmacy: [],
            prescriptionHistory: [],
            labTestHistory: [],
            diagnosisHistory: [],
            pharmacyHistory: [],
            temperature: [:],
            bp: "",
            pulse: "",
            respiration: "",
            insurance: "",
            insuranceType: [],
            insuranceName: []
        )
    }

    public func add(key: String, value: Any) -> PatientBuilder {
        switch key {
        case "sessionId":
            patient.sessionId = value as? String ?? ""
        case "age":
            patient.age = value as? String ?? ""
        case "gender":
            patient.gender = value as? String ?? ""
        case "insurance":
            patient.insurance = value as? String ?? ""
        case "insuranceType":
            patient.insuranceType = value as? [String] ?? []
        case "insuranceName":
            patient.insuranceName = value as? [String] ?? []
        case "temperature":
            patient.temperature = value as? [String: Any] ?? [:]
        case "bp":
            patient.bp = value as? String ?? ""
        case "pulse":
            patient.pulse = value as? String ?? ""
        case "respiration":
            patient.respiration = value as? String ?? ""
        case "labTest":
            patient.labTest = value as? [String] ?? []
        case "diagnosis":
            patient.diagnosis = value as? [String] ?? []
        case "prescription":
            patient.prescription = value as? [String] ?? []
        case "pharmacy":
            patient.pharmacy = value as? [String] ?? []
        case "labTestHistory":
            patient.labTestHistory = value as? [[String: Any]] ?? []
        case "diagnosisHistory":
            patient.diagnosisHistory = value as? [[String: Any]] ?? []
        case "prescriptionHistory":
            patient.prescriptionHistory = value as? [[String: Any]] ?? []
        case "pharmacyHistory":
            patient.pharmacyHistory = value as? [[String: Any]] ?? []
        default:
            break
        }
        return self
    }
    
//    public func add(key: String, value: Any) -> PatientBuilder {
//            switch key {
//            case "sessionId":
//                patient.sessionId = value as? String ?? ""
//            case "age":
//                patient.age = value as? String ?? ""
//            case "gender":
//                patient.gender = value as? String ?? ""
//            case "insurance":
//                patient.insurance = value as? String ?? ""
//            case "insuranceType":
//                patient.insuranceType = JsonUtility.unEscapeArray(value as? String ?? "") ?? []
//            case "insuranceName":
//                patient.insuranceName = JsonUtility.unEscapeArray(value as? String ?? "") ?? []
//            case "temperature":
//                patient.temperature = JsonUtility.unEscapeDictionary(escapedJSONString: value as? String ?? "") ?? [:]
//            case "bp":
//                patient.bp = value as? String ?? ""
//            case "pulse":
//                patient.pulse = value as? String ?? ""
//            case "respiration":
//                patient.respiration = value as? String ?? ""
//            case "labTest":
//                patient.labTest = JsonUtility.unEscapeArray(value as? String ?? "") ?? []
//            case "diagnosis":
//                patient.diagnosis = JsonUtility.unEscapeArray(value as? String ?? "") ?? []
//            case "prescription":
//                patient.prescription = JsonUtility.unEscapeArray(value as? String ?? "") ?? []
//            case "pharmacy":
//                patient.pharmacy = JsonUtility.unEscapeArray(value as? String ?? "") ?? []
//            case "labTestHistory":
//                if let jsonArray = JsonUtility.convertEscapedJSONStringToArray(value as! String) {
//                    print(jsonArray)
//                    patient.labTestHistory = jsonArray
//                } else {
//                    print("Failed to convert JSON string")
//                }
//            case "diagnosisHistory":
//                if let jsonArray = JsonUtility.convertEscapedJSONStringToArray(value as! String) {
//                    print(jsonArray)
//                    patient.diagnosisHistory = jsonArray
//                } else {
//                    print("Failed to convert JSON string")
//                }
//            case "prescriptionHistory":
//                if let jsonArray = JsonUtility.convertEscapedJSONStringToArray(value as! String) {
//                    print(jsonArray)
//                    patient.prescriptionHistory = jsonArray
//                } else {
//                    print("Failed to convert JSON string")
//                }
//            case "pharmacyHistory":
//                if let jsonArray = JsonUtility.convertEscapedJSONStringToArray(value as! String) {
//                    print(jsonArray)
//                    patient.pharmacyHistory = jsonArray
//                } else {
//                    print("Failed to convert JSON string")
//                }
//            default:
//                break
//            }
//            return self
//        }
    
    func unEscapeArrayDictionary(escapedJSONString: String) -> [String: String]? {
        // Convert escaped JSON string to Data
        if let jsonData = escapedJSONString.data(using: .utf8) {
            // Decode JSON data to a dictionary
            let decoder = JSONDecoder()
            do {
                // Define a dictionary with String keys and values
                let dictionary = try decoder.decode([String: String].self, from: jsonData)
                print(dictionary) // Output: ["v": "88.56", "u": "Fahrenheit/Celsius"]
                return dictionary;
            } catch {
                print("Failed to decode JSON:", error)
            }
        }
        return nil
    }
    
    public func build() -> Patient {
        return patient
    }

}
