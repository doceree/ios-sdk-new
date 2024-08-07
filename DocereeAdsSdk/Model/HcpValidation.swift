//
//  HcpValidation.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 01/04/24.
//

import Foundation

// MARK: - HcpValidation
struct HcpValidationData: Codable {
    let siteId: Int?
    let script: String?
    let platformType: Int?
    let consentPositionId: Int?
    let font: String?
    let fontUrl: String?
    let fontColour: String?
    let closeUrl: String?
    let acceptUrl: String?
    let valStatus: Int?
    enum CodingKeys: String, CodingKey {
        case siteId
        case script     
        case platformType
        case consentPositionId
        case font
        case fontUrl
        case fontColour
        case closeUrl
        case acceptUrl
        case valStatus
    }

}

struct HcpValidation: Codable {
    let timestamp: String?
    let code: Int?
    let status: String?
    let message: String?
    let data: HcpValidationData

    enum CodingKeys: String, CodingKey {
        case timestamp
        case code
        case status
        case message
        case data
    }
}
