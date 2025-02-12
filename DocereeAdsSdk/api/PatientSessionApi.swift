//
//  PatientSessionApi.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 30/05/24.
//

import Foundation

struct Constants {
    static let HcpData = "HcpData"
}

struct Strings {
    static let CONSTANT = Constants()
}

class PatientSessionApi {
    
    static func send(sessionId: String = "", status: Int = 0) async throws {
        let header = Header()
        var headerJson: [String: String] = [:]
        
        do {
            headerJson = try await header.getHeaders()
            print("Fetching data:", headerJson)
        } catch {
            print("PatientSessionApi Error fetching header:", error)
            throw error
        }
        
        guard let hcpData = DocereeMobileAds.shared().getProfile() else {
            print("Error: Not found profile data")
            return
        }

        // Safely unwrap the optional values
        if let unwrappedUid = getIdentifierForAdvertising(), let unwrappedHid = hcpData.hcpId {
            // Construct the URL string by concatenating the components
            let path = LibNetwork.getBaseUrl(mode: DocereeMobileAds.shared().getEnvironment())
            let urlString = "\(path)\(LibNetwork.patientSessionPath)?uid=\(unwrappedUid)&sid=\(sessionId)&hid=\(unwrappedHid)&status=\(status)&eType=\(4)"
            print("Corrected URL: \(urlString)")
            
            // Convert the string to a URL object if needed
            if let url = URL(string: urlString) {
                // Use the URL as needed, for example, in a network request
                print("URL object: \(url)")
  
                var request = URLRequest(url: url)
                request.allHTTPHeaderFields = headerJson
                
                do {
                    let (_, response) = try await URLSession.shared.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        print("PatientSessionApi response:", httpResponse.statusCode)
                    } else {
                        print("PatientSessionApi response:", (response as? HTTPURLResponse)?.statusCode ?? 0)
                        throw URLError(.badServerResponse)
                    }
                } catch {
                    print("PatientSessionApi Failed Api:", error)
                    throw error
                }
                
            } else {
                print("Failed to create URL object from string")
            }
        } else {
            print("UID or HID is nil")
        }
        

    }
}

// Placeholder for LibNetwork class
class LibNetwork {
    static func getBaseUrl(mode: EnvironmentType) -> String {
        if(mode == .Dev) {
          return "https://dev-bidder.doceree.com";
        }else if(mode == .Qa){
          return "https://qa-ad-test.doceree.com";
        }
        return "https://dai.doceree.com";
    }
    
    static var patientSessionPath: String {
        return "/drs/nEvent"
    }
}
