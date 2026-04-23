//
//  ConfigurationService.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 12/05/25.
//

import Foundation

class ConfigurationService {
    static let shared = ConfigurationService()

    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Performs the POST, validates HTTP status, and decodes JSON. Retries transient 5xx and common `URLError`s with bounded backoff. Does not read or write `UserDefaults`.
    internal func executeAppConfigurationRequest(_ request: URLRequest) async throws -> AppConfiguration {
        for attempt in 0..<DocereeHTTPTransportRetry.maxAttempts {
            try Task.checkCancellation()
            do {
                return try await performAppConfigurationRequestOnce(request)
            } catch is CancellationError {
                throw CancellationError()
            } catch let serviceError as AppConfigurationServiceError {
                if Self.shouldRetry(appConfigurationError: serviceError), attempt < DocereeHTTPTransportRetry.maxAttempts - 1 {
                    DocereeLog.debug("App config: attempt \(attempt + 1) failed (\(serviceError)), retrying")
                    try await Task.sleep(nanoseconds: DocereeHTTPTransportRetry.backoffNanoseconds(afterFailureAtAttempt: attempt))
                    continue
                }
                throw serviceError
            } catch let urlError as URLError {
                if DocereeHTTPTransportRetry.shouldRetry(urlError: urlError), attempt < DocereeHTTPTransportRetry.maxAttempts - 1 {
                    DocereeLog.debug("App config: attempt \(attempt + 1) URLError \(urlError.code.rawValue), retrying")
                    try await Task.sleep(nanoseconds: DocereeHTTPTransportRetry.backoffNanoseconds(afterFailureAtAttempt: attempt))
                    continue
                }
                throw urlError
            } catch {
                throw error
            }
        }
        throw AppConfigurationServiceError.invalidHTTPResponse
    }

    private func performAppConfigurationRequestOnce(_ request: URLRequest) async throws -> AppConfiguration {
        try Task.checkCancellation()
        let (data, response) = try await urlSession.data(for: request)
        try Task.checkCancellation()
        guard let httpResponse = response as? HTTPURLResponse else {
            DocereeLog.debug("App config: non-HTTP response")
            throw AppConfigurationServiceError.invalidHTTPResponse
        }
        let status = httpResponse.statusCode
        guard (200...299).contains(status) else {
            let preview = Self.responseBodyPreview(from: data)
            let err = AppConfigurationServiceError.httpStatusNotSuccess(statusCode: status, responseBodyPreview: preview)
            DocereeLog.debug("\(err.localizedDescription)")
            throw err
        }
        do {
            return try Self.decodeAppConfiguration(from: data)
        } catch {
            let preview = Self.responseBodyPreview(from: data)
            let wrapped = AppConfigurationServiceError.decodingFailed(underlying: error, responseBodyPreview: preview)
            DocereeLog.debug("\(wrapped.localizedDescription)")
            throw wrapped
        }
    }

    private static func shouldRetry(appConfigurationError: AppConfigurationServiceError) -> Bool {
        if case .httpStatusNotSuccess(let code, _) = appConfigurationError {
            return DocereeHTTPTransportRetry.shouldRetry(httpStatusCode: code)
        }
        return false
    }

    /// Builds the HTTPS URL used for app configuration fetch (same string as production).
    static func makeAppConfigurationURL(identityHost: String, environment: EnvironmentType) -> URL? {
        let path = getPath(methodName: Methods.AppConfig, type: environment)
        return URL(string: "https://\(identityHost)\(path)")
    }

    private static func responseBodyPreview(from data: Data, limit: Int = 500) -> String? {
        guard !data.isEmpty else { return nil }
        return String(data: data, encoding: .utf8).map { String($0.prefix(limit)) }
    }

    static func decodeAppConfiguration(from data: Data) throws -> AppConfiguration {
        try JSONDecoder().decode(AppConfiguration.self, from: data)
    }
    
    func fetchAppConfiguration(appId: String) async -> AppConfigurationFetchOutcome {
        if UserDefaultsManager.shared.isConfigValid() {
            DocereeLog.debug("Config still valid")
            return .usedValidCache
        }
        DocereeLog.debug("Config expired, refresh needed")
        if Task.isCancelled {
            return .cancelled
        }

        let environment = DocereeMobileAds.shared().getEnvironment()
        let host = getIdentityHost(type: environment)
        guard let appKey = DocereeMobileAds().loadDocereeIdentifier(from: DocereeAdsIdArchivingUrl) else {
            return .missingApplicationKey
        }
        if Task.isCancelled {
            return .cancelled
        }

        guard let url = Self.makeAppConfigurationURL(identityHost: host, environment: environment) else {
            DocereeLog.debug("Invalid configuration URL (environment=\(environment), host=\(host))")
            return .invalidConfigurationURL(environment: environment, identityHost: host)
        }
        DocereeLog.debug("App config fetch: environment=\(environment), url=\(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = DocereeHTTPTimeouts.interactiveRequest
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appKey, forHTTPHeaderField: "X-Requested-With")

        let body = ["appId": appId]
        let bodyData: Data
        do {
            bodyData = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return .requestEncodingFailed(underlying: error)
        }
        request.httpBody = bodyData

        if Task.isCancelled {
            return .cancelled
        }

        UserDefaultsManager.shared.deleteConfig()
        UserDefaultsManager.shared.clearConfigExpiration()

        do {
            let decoded = try await executeAppConfigurationRequest(request)
            if Task.isCancelled {
                return .cancelled
            }
            UserDefaultsManager.shared.saveConfigExpiration()
            UserDefaultsManager.shared.saveConfig(decoded.data)
            return .refreshed(decoded)
        } catch is CancellationError {
            return .cancelled
        } catch {
            return .fetchFailed(underlying: error)
        }
    }
}
