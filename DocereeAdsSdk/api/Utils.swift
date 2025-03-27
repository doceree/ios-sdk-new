//
//  Utils.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 30/05/24.
//

import Foundation

class Utils {

    // Function to replace string in JSON
    func replaceStringInJSON(jsonString: String) -> String {
        return jsonString.replacingOccurrences(of: "Fahrenheit\\/Celsius", with: "Fahrenheit/Celsius")
    }
    
    // Function to encode a string to Base64
    func encodeBase64(_ str: String) throws -> String {
        guard let data = str.data(using: .utf8) else {
            throw NSError(domain: "UtilsErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "The input must be a string."])
        }
        return data.base64EncodedString()
    }

    // Generate a session ID
    func sessionId() async throws -> String {
        let header = Header()
        let appInfo = try await header.getAppInfo()
        let bundleId = appInfo.bundleId

        let seed = "DE"
        let version = "V1"
        var uid = ""
        var num1 = 0
        let random = Double.random(in: 0..<1)
        var dateAbs: Int64 = 0
        let time = Date().timeIntervalSince1970

        let hashGen: (String) -> Int = { s in
            s.reduce(0) { (($0 << 5) &- $0) &+ Int($1.asciiValue!) }
        }
        dateAbs = abs(Int64(Date().addingTimeInterval(random * 999 * 99).timeIntervalSince1970 * 1000))
        num1 = abs(hashGen(bundleId))

        let str = "\(dateAbs + Int64(Date().timeIntervalSince1970 * 1000))"
        let num2 = String(str.reversed()).prefix(5)
        let num3 = Int.random(in: 0..<99999) * 99
        uid = String((num1 + Int(num2)! + num3) + num3)
        print("sessionId Generated UID:", uid)

        let sessionId = "\(seed).\(version).\(uid).\(Int(time))"
        print("sessionId sessionId:", sessionId)

        return sessionId
    }

}

