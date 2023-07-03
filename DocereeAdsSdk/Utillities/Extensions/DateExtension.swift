//
//  DateExtension.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 19/06/23.
//

import Foundation

extension DateFormatter {

    static let iso8601DateFormatter: DateFormatter = {
        let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
        let iso8601DateFormatter = DateFormatter()
        iso8601DateFormatter.locale = enUSPOSIXLocale
        iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        iso8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return iso8601DateFormatter
    }()

    static let iso8601WithoutMillisecondsDateFormatter: DateFormatter = {
        let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
        let iso8601DateFormatter = DateFormatter()
        iso8601DateFormatter.locale = enUSPOSIXLocale
        iso8601DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        iso8601DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return iso8601DateFormatter
    }()

    static func date(fromISO8601String string: String) -> Date? {
        if let dateWithMilliseconds = iso8601DateFormatter.date(from: string) {
            return dateWithMilliseconds
        }

        if let dateWithoutMilliseconds = iso8601WithoutMillisecondsDateFormatter.date(from: string) {
            return dateWithoutMilliseconds
        }

        return nil
    }
}

extension Date {
    static func getFormattedDate() -> String {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        let dateString = df.string(from: date)

        return dateString
    }
}
