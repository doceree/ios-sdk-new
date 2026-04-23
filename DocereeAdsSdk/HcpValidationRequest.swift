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
    
    internal func getHcpSelfValidation(completion: @escaping(_ results: Results) -> Void) async {
        self.requestHttpHeaders.add(value: "application/json", forKey: "Content-Type")

        let uuid = await getUUID()
        let josnObject: [String: Any] = [
            GetHcpValidation.bundleId.rawValue: Bundle.main.bundleIdentifier!,
            GetHcpValidation.uuid.rawValue: uuid as Any,
            GetHcpValidation.userId.rawValue: uuid as Any,
        ]

        var components = URLComponents()
        components.scheme = "https"
        components.host = getIdentityHost(type: DocereeMobileAds.shared().getEnvironment())
        components.path = getPath(methodName: Methods.GetHcpValidation, type: DocereeMobileAds.shared().getEnvironment())
        guard let collectDataEndPoint = components.url else {
            await MainActor.run {
                completion(Results(withData: nil, response: nil, error: HcpRequestError.apiFailed))
            }
            return
        }
        var request = URLRequest(url: collectDataEndPoint)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        for header in requestHttpHeaders.allValues() {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        request.httpMethod = HttpMethod.post.rawValue

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: josnObject, options: [])
        } catch {
            await MainActor.run {
                completion(Results(withData: nil, response: nil, error: HcpRequestError.apiFailed))
            }
            return
        }
        request.httpBody = jsonData

        do {
            let (data, http) = try await DocereeURLSessionLoading.dataWithInteractiveRetries(for: request)
            do {
                let decode = try JSONDecoder().decode(HcpValidation.self, from: data)
                DocereeLog.debug("hcpValidationData: \(decode)")
                if decode.code != 200 {
                    await MainActor.run {
                        completion(Results(withData: nil, response: http, error: HcpRequestError.apiFailed))
                    }
                    return
                }
                await MainActor.run {
                    completion(Results(withData: data, response: http, error: nil))
                }
            } catch {
                await MainActor.run {
                    completion(Results(withData: nil, response: http, error: HcpRequestError.parsingError))
                }
            }
        } catch {
            DocereeLog.debug("getHcpSelfValidation failed: \(error.localizedDescription)")
            await MainActor.run {
                completion(Results(withData: nil, response: nil, error: HcpRequestError.apiFailed))
            }
        }
    }
    
    internal func updateHcpSelfValidation(_ hcpStatus: String) {

        let advertisementId = getIdentifierForAdvertising()
        if (advertisementId == nil) {
            if #available(iOS 10.0, *) {
                os_log("Error: Ad Tracking is disabled . Please re-enable it to view ads", log: .default, type: .error)
            } else {
                // Fallback on earlier versions
                DocereeLog.debug("Error: Ad Tracking is disabled . Please re-enable it to view ads")
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

        let body = josnObject
        var components = URLComponents()
        components.scheme = "https"
        components.host = getIdentityHost(type: DocereeMobileAds.shared().getEnvironment())
        components.path = getPath(methodName: Methods.UpdateHcpValidation, type: DocereeMobileAds.shared().getEnvironment())
        guard let collectDataEndPoint = components.url else {
            DocereeLog.debug("updateHcpSelfValidation: invalid URL")
            return
        }
        var request = URLRequest(url: collectDataEndPoint)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        for header in requestHttpHeaders.allValues() {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        request.httpMethod = HttpMethod.post.rawValue

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            return
        }
        request.httpBody = jsonData

        Task {
            do {
                let (_, http) = try await DocereeURLSessionLoading.dataWithInteractiveRetries(for: request)
                DocereeLog.debug("Hcp update HTTP \(http.statusCode)")
            } catch {
                DocereeLog.debug("Hcp update request failed: \(error.localizedDescription)")
            }
        }
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

        Task {
            do {
                let (data, _) = try await DocereeURLSessionLoading.dataWithInteractiveRetries(for: URLRequest(url: url))
                guard let cssString = String(data: data, encoding: .utf8) else {
                    completion(nil)
                    return
                }
                completion(extractFontFileURL(from: cssString))
            } catch {
                DocereeLog.debug("GoogleFontLoader: CSS fetch failed — \(error.localizedDescription)")
                completion(nil)
            }
        }
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

        Task {
            do {
                let (fontData, _) = try await DocereeURLSessionLoading.dataWithInteractiveRetries(for: URLRequest(url: fontURL))
                guard let dataProvider = CGDataProvider(data: fontData as CFData),
                      let font = CGFont(dataProvider) else {
                    await MainActor.run { completion(false) }
                    return
                }

                var errorRef: Unmanaged<CFError>?
                guard CTFontManagerRegisterGraphicsFont(font, &errorRef) else {
                    await MainActor.run { completion(false) }
                    return
                }

                await MainActor.run { completion(true) }
            } catch {
                DocereeLog.debug("GoogleFontLoader: font download failed — \(error.localizedDescription)")
                await MainActor.run { completion(false) }
            }
        }
    }
}
