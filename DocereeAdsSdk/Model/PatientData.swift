//
//  PatientData.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 24/07/24.
//

import Foundation

/// A struct to represent patient data
struct PatientData: Codable {
    static var shared = PatientData()

    var sessionId: String = "sid"
    var age: String = "ag"
    var gender: String = "gd"
    var insurance: String = "ins"
    var insuranceType: String = "instyp"
    var insuranceName: String = "insnm"
    var temperature: String = "tm"
    var bp: String = "bp"
    var pulse: String = "ps"
    var respiration: String = "rr"
    var labTest: String = "lt"
    var diagnosis: String = "dx"
    var prescription: String = "rx"
    var pharmacy: String = "ph"
    var labTestHistory: String = "lth"
    var diagnosisHistory: String = "dxh"
    var prescriptionHistory: String = "rxh"
    var pharmacyHistory: String = "phh"

    private init() {}
}
