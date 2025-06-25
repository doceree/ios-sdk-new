//
//  Enums.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 02/04/24.
//

import Foundation

enum GetHcpValidation: String {
    case bundleId = "bundleId"
    case uuid = "uuid"
    case userId = "userid"
}

enum UpdateHcpValidation: String {
    case bundleId = "bundleId"
    case uuid = "uuid"
    case hcpStatus = "hcpStatus"
    case userId = "userid"
}

enum ExpirationDuration {
//    static let minutes2: TimeInterval = 2 * 60 // 2 minutes  in seconds
//    static let minutes5: TimeInterval = 5 * 60 // 5 minutes  in seconds
//    static let minutes10: TimeInterval = 10 * 60 // 10 minutes in seconds
    static let hours6: TimeInterval = 6 * 60 * 60 // 6 hours in seconds
    static let days15: TimeInterval = 15 * 24 * 60 * 60 // 15 days in seconds
    static let year1: TimeInterval = 365 * 24 * 60 * 60 // 1 year in seconds
}

public enum PopupAction: String {
    case accept = "1"
    case reject = "0"
    case close = "-1"
    
}
