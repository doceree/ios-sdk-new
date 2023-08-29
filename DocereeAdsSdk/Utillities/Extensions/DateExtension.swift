//
//  DateExtension.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 25/08/23.
//

import Foundation

extension Date {
    static func getFormattedDate() -> String {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        let dateString = df.string(from: date)

        return dateString
    }
}

extension Date {
    static func currentTimeMillis() -> String {
        return "\(Int64(Date().timeIntervalSince1970 * 1000))"
    }
}
