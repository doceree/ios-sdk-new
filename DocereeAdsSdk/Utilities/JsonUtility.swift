//
//  JsonUtility.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 26/07/24.
//

import Foundation

// Utility class for JSON handling
class JsonUtility {
    // Method to convert an escaped JSON string to an array of dictionaries
    static func decodeJSON<T: Decodable>(_ jsonString: String, as type: T.Type) -> T? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            DocereeLog.debug("Error converting string to Data")
            return nil
        }
        
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: jsonData)
            return decodedObject
        } catch {
            DocereeLog.debug("Failed to decode JSON: \(error)")
            return nil
        }
    }
    
    static func unescapeString(escapedString: String) -> String? {
        guard let data = escapedString.data(using: .utf8) else {
            DocereeLog.debug("Failed to convert string to data")
            return nil
        }
        
        do {
            // Decode the data as JSON to unescape it
            if let decodedString = try JSONSerialization.jsonObject(with: data, options: []) as? String {
                return decodedString
            }
        } catch {
            DocereeLog.debug("Error decoding JSON: \(error.localizedDescription)")
        }
        return nil
    }
    
    static func unEscapeDictionary(escapedJSONString: String) -> [String: String]? {
        // Convert escaped JSON string to Data
        if let jsonData = escapedJSONString.data(using: .utf8) {
            // Decode JSON data to a dictionary
            let decoder = JSONDecoder()
            do {
                // Define a dictionary with String keys and values
                let dictionary = try decoder.decode([String: String].self, from: jsonData)
                DocereeLog.debug("\(dictionary)") // Output: ["v": "88.56", "u": "Fahrenheit/Celsius"]
                return dictionary;
            } catch {
                DocereeLog.debug("Failed to decode JSON: \(error)")
            }
        }
        return nil
    }
   
    // Method to convert an escaped JSON string to an array
    static func unEscapeArray(_ escapedJSONString: String) -> [String]? {
        guard let jsonData = escapedJSONString.data(using: .utf8) else {
            DocereeLog.debug("Error converting string to Data")
            return nil
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            if let jsonArray = jsonObject as? [String] {
                return jsonArray
            } else {
                DocereeLog.debug("Unexpected JSON format")
                return nil
            }
        } catch {
            DocereeLog.debug("Failed to decode JSON: \(error)")
            return nil
        }
    }
    
    // Method to convert an escaped JSON string to an array of dictionaries
    static func convertEscapedJSONStringToArray(_ escapedJSONString: String) -> [[String: Any]]? {
        guard let jsonData = escapedJSONString.data(using: .utf8) else {
            DocereeLog.debug("Error converting string to Data")
            return nil
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            if let jsonArray = jsonObject as? [[String: Any]] {
                return jsonArray
            } else {
                DocereeLog.debug("Unexpected JSON format")
                return nil
            }
        } catch {
            DocereeLog.debug("Failed to decode JSON: \(error)")
            return nil
        }
    }
}
