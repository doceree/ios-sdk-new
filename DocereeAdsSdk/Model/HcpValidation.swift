

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
    let acceptUrl: String?
    let closeUrl: String?
    let templateId: Int?
    let font: String?
    let fontColour: String?
    let fontUrl: String?
    let platformType: Int?
    let consentPositionId: Int?
    let valStatus: Int?

    enum CodingKeys: String, CodingKey {
        case siteId
        case script
        case acceptUrl
        case closeUrl
        case templateId
        case font
        case fontColour
        case fontUrl
        case platformType
        case consentPositionId
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


