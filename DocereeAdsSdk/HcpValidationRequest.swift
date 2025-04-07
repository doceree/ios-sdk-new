//
//  HcpValidationRequest.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 01/04/24.
//

import UIKit
import os.log
import CoreText

public final class HcpValidationRequest {
    
    // MARK: Properties
    var requestHttpHeaders = RestEntity()
    
    // todo: create a queue of requests and inititate request
    public init() {
    }
    
    internal func getHcpSelfValidation(completion: @escaping(_ results: Results) -> Void) {

        self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
        
        // query params
        let josnObject: [String : Any] = [
            GetHcpValidation.bundleId.rawValue : Bundle.main.bundleIdentifier!,
            GetHcpValidation.uuid.rawValue : getUUID() as Any,
            GetHcpValidation.userId.rawValue : getUUID() as Any,
        ]

        let body = josnObject //httpBodyParameters.allValues()
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        var components = URLComponents()
        components.scheme = "https"
        components.host = getDataCollectionHost(type: DocereeMobileAds.shared().getEnvironment())
        components.path = getPath(methodName: Methods.GetHcpValidation, type: DocereeMobileAds.shared().getEnvironment())
        let collectDataEndPoint: URL = components.url!
        var request: URLRequest = URLRequest(url: collectDataEndPoint)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // set headers
        for header in requestHttpHeaders.allValues() {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        request.httpMethod = HttpMethod.post.rawValue
        
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            return
        }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard data != nil else { return }
            let urlResponse = response as! HTTPURLResponse
//            data?.printJSON()

            if urlResponse.statusCode == 200 {
                do {
                    let decode = try JSONDecoder().decode(HcpValidation.self, from: data!)
                    print("hcpValidationData: ",decode)
                    if decode.code != 200 {
                        completion(Results(withData: nil, response: response as? HTTPURLResponse, error: HcpRequestError.apiFailed))
                        return
                    }
                    completion(Results(withData: data, response: response as? HTTPURLResponse, error: nil))
                } catch {
                    completion(Results(withData: nil, response: response as? HTTPURLResponse, error: HcpRequestError.parsingError))
                }
            } else {
                completion(Results(withData: nil, response: response as? HTTPURLResponse, error: HcpRequestError.apiFailed))
            }
        }
        task.resume()

    }
    
    internal func updateHcpSelfValidation(_ hcpStatus: String) {

        let advertisementId = getIdentifierForAdvertising()
        if (advertisementId == nil) {
            if #available(iOS 10.0, *) {
                os_log("Error: Ad Tracking is disabled . Please re-enable it to view ads", log: .default, type: .error)
            } else {
                // Fallback on earlier versions
                print("Error: Ad Tracking is disabled . Please re-enable it to view ads")
            }
            return
        }
        
        self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")
        
        // query params
        let josnObject: [String : Any] = [
            UpdateHcpValidation.bundleId.rawValue : Bundle.main.bundleIdentifier!,
            UpdateHcpValidation.uuid.rawValue : advertisementId as Any,
            UpdateHcpValidation.hcpStatus.rawValue : hcpStatus as Any,
            UpdateHcpValidation.userId.rawValue : advertisementId as Any,
        ]

        let body = josnObject //httpBodyParameters.allValues()
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        var components = URLComponents()
        components.scheme = "https"
        components.host = getDataCollectionHost(type: DocereeMobileAds.shared().getEnvironment())
        components.path = getPath(methodName: Methods.UpdateHcpValidation, type: DocereeMobileAds.shared().getEnvironment())
        let collectDataEndPoint: URL = components.url!
        var request: URLRequest = URLRequest(url: collectDataEndPoint)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // set headers
        for header in requestHttpHeaders.allValues() {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        request.httpMethod = HttpMethod.post.rawValue
        
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            return
        }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard data != nil else { return }
            let urlResponse = response as! HTTPURLResponse
            guard data != nil else { return }
            #if DEBUG
                print("Hcp Updated:", urlResponse.statusCode)
            #endif
            
            if urlResponse.statusCode == 200 {
                #if DEBUG
                    print("Hcp Updated:", urlResponse.statusCode)
                #endif
            } else {
                print("Hcp Updation Failed:", urlResponse.statusCode)
            }
        }
        task.resume()

    }
}



public class GoogleFontLoader {
    
    private static var fontCache: [String: UIFont] = [:] // ✅ Font cache to store loaded fonts
    
    /// Loads a Google Font dynamically and applies it to a UILabel
    public static func loadFont(fontName: String, googleFontURL: String, fontSize: CGFloat, completion: @escaping (UIFont?) -> Void) {
        // ✅ If the font is already downloaded, return it from cache
        if let cachedFont = fontCache[fontName] {
            completion(cachedFont)
            return
        }

        fetchGoogleFontCSS(from: googleFontURL) { fontFileURL in
            guard let fontFileURL = fontFileURL else {
                completion(nil)
                return
            }

            downloadAndRegisterFont(from: fontFileURL, fontName: fontName) { success in
                DispatchQueue.main.async {
                    if success {
                        let font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
                        fontCache[fontName] = font // ✅ Store font in cache
                        completion(font)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    private static func fetchGoogleFontCSS(from urlString: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let cssString = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            completion(extractFontFileURL(from: cssString))
        }
        task.resume()
    }

    private static func extractFontFileURL(from css: String) -> String? {
        let pattern = "url\\((https:[^)]*\\.ttf)\\)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(css.startIndex..., in: css)

        if let match = regex?.firstMatch(in: css, options: [], range: range),
           let ttfRange = Range(match.range(at: 1), in: css) {
            return String(css[ttfRange])
        }
        return nil
    }

    private static func downloadAndRegisterFont(from urlString: String, fontName: String, completion: @escaping (Bool) -> Void) {
        guard let fontURL = URL(string: urlString) else {
            completion(false)
            return
        }

        let task = URLSession.shared.downloadTask(with: fontURL) { location, response, error in
            guard let location = location, error == nil else {
                completion(false)
                return
            }

            let fontData = try? Data(contentsOf: location)
            guard let dataProvider = CGDataProvider(data: fontData! as CFData),
                  let font = CGFont(dataProvider) else {
                completion(false)
                return
            }

            var errorRef: Unmanaged<CFError>?
            if !CTFontManagerRegisterGraphicsFont(font, &errorRef) {
                completion(false)
                return
            }

            DispatchQueue.main.async {
                completion(true)
            }
        }
        task.resume()
    }
}
