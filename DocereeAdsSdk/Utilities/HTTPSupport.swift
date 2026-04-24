
import Foundation

struct HTTPMethod {
	static let get = "GET"
	static let post = "POST"
	static let put = "PUT"
    static let delete = "DELETE"
}

struct HTTPHeaderKey {
	static let contentType = "Content-Type"
	static let authorization = "Authorization"
    static let platform = "Platform"
}

struct HTTPHeaderValue {
	static let applicationJson = "application/json"
}

extension HTTPHeaderValue {
    static var platformInfo: String {
        return "iOS 13.0"
//        return UIApplication.osName + ";" + UIApplication.buildVersion
    }

}

enum HttpMethod: String {
    case get
    case post
}

/// Default `URLRequest.timeoutInterval` values (seconds) for SDK network calls.
public enum DocereeHTTPTimeouts: Sendable {
    /// User-visible fetches (ads, configuration, and similar).
    public static let interactiveRequest: TimeInterval = 30
    /// Fire-and-forget beacons (impression, viewability, ad-block reporting).
    public static let beaconRequest: TimeInterval = 5
}

// MARK: - Shared transport (retries + `URLSession`)

/// Retry policy shared by configuration, ad requests, patient session, HCP validation, and similar SDK HTTP work.
internal enum DocereeHTTPTransportRetry: Sendable {
    internal static let maxAttempts = 3

    internal static func backoffNanoseconds(afterFailureAtAttempt attempt: Int) -> UInt64 {
        let cappedShift = min(attempt, 10)
        return 200_000_000 * UInt64(1 << cappedShift)
    }

    internal static func shouldRetry(urlError: URLError) -> Bool {
        switch urlError.code {
        case .timedOut,
             .networkConnectionLost,
             .notConnectedToInternet,
             .cannotConnectToHost,
             .cannotFindHost,
             .dnsLookupFailed,
             .internationalRoamingOff,
             .callIsActive,
             .dataNotAllowed:
            return true
        default:
            return false
        }
    }

    internal static func shouldRetry(httpStatusCode: Int) -> Bool {
        (500...599).contains(httpStatusCode)
    }
}

internal enum DocereeURLSessionLoadingError: Error {
    case invalidHTTPResponse
}

/// Single entry for `URLSession.data` with interactive timeout, **2xx** success, bounded **5xx** / transient **`URLError`** retries.
internal enum DocereeURLSessionLoading {
    internal static func dataWithInteractiveRetries(
        for request: URLRequest,
        session: URLSession = .shared
    ) async throws -> (Data, HTTPURLResponse) {
        let signpost = DocereeSignposts.networkInterval("doceree.interactive_data")
        defer { signpost.end() }
        var req = request
        if req.timeoutInterval <= 0 {
            req.timeoutInterval = DocereeHTTPTimeouts.interactiveRequest
        }
        for attempt in 0..<DocereeHTTPTransportRetry.maxAttempts {
            try Task.checkCancellation()
            do {
                let (data, response) = try await session.data(for: req)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse else {
                    DocereeLog.debug("DocereeURLSessionLoading: non-HTTP response")
                    throw DocereeURLSessionLoadingError.invalidHTTPResponse
                }
                if (200...299).contains(http.statusCode) {
                    return (data, http)
                }
                DocereeLog.debug("DocereeURLSessionLoading: HTTP \(http.statusCode)")
                if DocereeHTTPTransportRetry.shouldRetry(httpStatusCode: http.statusCode),
                   attempt < DocereeHTTPTransportRetry.maxAttempts - 1 {
                    try await Task.sleep(nanoseconds: DocereeHTTPTransportRetry.backoffNanoseconds(afterFailureAtAttempt: attempt))
                    continue
                }
                throw URLError(.badServerResponse)
            } catch is CancellationError {
                throw CancellationError()
            } catch DocereeURLSessionLoadingError.invalidHTTPResponse {
                throw DocereeURLSessionLoadingError.invalidHTTPResponse
            } catch let urlError as URLError {
                if DocereeHTTPTransportRetry.shouldRetry(urlError: urlError),
                   attempt < DocereeHTTPTransportRetry.maxAttempts - 1 {
                    DocereeLog.debug("DocereeURLSessionLoading: URLError \(urlError.code.rawValue), retrying")
                    try await Task.sleep(nanoseconds: DocereeHTTPTransportRetry.backoffNanoseconds(afterFailureAtAttempt: attempt))
                    continue
                }
                throw urlError
            }
        }
        throw URLError(.unknown)
    }
}

// MARK: - Beacons (fire-and-forget)

/// Best-effort beacon sends: **`DocereeHTTPTimeouts.beaconRequest`**, **2xx** success, bounded retries for **5xx**, transient **`URLError`**, and non-HTTP responses.
internal enum DocereeURLSessionBeacon {
    private static let maxAttempts = DocereeHTTPTransportRetry.maxAttempts

    internal static func sendWithRetries(for request: URLRequest, session: URLSession, message: String) async {
        let signpost = DocereeSignposts.networkInterval("doceree.beacon_send")
        defer { signpost.end() }
        var req = request
        req.timeoutInterval = DocereeHTTPTimeouts.beaconRequest

        for attempt in 0..<maxAttempts {
            do {
                try Task.checkCancellation()
                let (_, response) = try await session.data(for: req)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse else {
                    DocereeLog.debug("\(message) non-HTTP response (attempt \(attempt + 1))")
                    if attempt < maxAttempts - 1 {
                        try await Task.sleep(nanoseconds: DocereeHTTPTransportRetry.backoffNanoseconds(afterFailureAtAttempt: attempt))
                    }
                    continue
                }
                if (200...299).contains(http.statusCode) {
                    DocereeLog.debug("\(message) OK status \(http.statusCode)")
                    return
                }
                DocereeLog.debug("\(message) HTTP \(http.statusCode) (attempt \(attempt + 1))")
                if DocereeHTTPTransportRetry.shouldRetry(httpStatusCode: http.statusCode),
                   attempt < maxAttempts - 1 {
                    try await Task.sleep(nanoseconds: DocereeHTTPTransportRetry.backoffNanoseconds(afterFailureAtAttempt: attempt))
                    continue
                }
                return
            } catch is CancellationError {
                return
            } catch let urlError as URLError {
                DocereeLog.debug("\(message) transport error: \(urlError.localizedDescription) (attempt \(attempt + 1))")
                if DocereeHTTPTransportRetry.shouldRetry(urlError: urlError),
                   attempt < maxAttempts - 1 {
                    do {
                        try await Task.sleep(nanoseconds: DocereeHTTPTransportRetry.backoffNanoseconds(afterFailureAtAttempt: attempt))
                    } catch is CancellationError {
                        return
                    } catch {}
                    continue
                }
                return
            } catch {
                DocereeLog.debug("\(message) transport error: \(error.localizedDescription) (attempt \(attempt + 1))")
                if attempt < maxAttempts - 1 {
                    do {
                        try await Task.sleep(nanoseconds: DocereeHTTPTransportRetry.backoffNanoseconds(afterFailureAtAttempt: attempt))
                    } catch is CancellationError {
                        return
                    } catch {}
                    continue
                }
                return
            }
        }
    }
}

func getHost(type: EnvironmentType) -> String {
    switch type {
    case .Dev:
        return "dev-bidder.doceree.com"
    case .Local:
        return "10.0.3.2"
    case .Qa:
        return "qa-ad-test.doceree.com"
    case .Prod:
        return "dai.doceree.com"
    }
}

func getDocTrackerHost(type: EnvironmentType) -> String {
    switch type {
    case .Dev:
        return "dev-tracking.doceree.com"
    case .Local:
        return "10.0.3.2"
    case .Qa:
        return "qa-ad-test.doceree.com"
    case .Prod:
        return "dai.doceree.com"
    }
}

func getIdentityHost(type: EnvironmentType) -> String {
    switch type {
    case .Dev:
        return "qa-identity.doceree.com"
    case .Local:
        return "10.0.3.2"
    case .Qa:
        return "qa-identity.doceree.com"
    case .Prod:
        return "dai.doceree.com"
    }
}

enum Methods{
    case GetImage
    case AdBlock
    case GetHcpValidation
    case UpdateHcpValidation
    case PatientSession
    case AppConfig
}

func getPath(methodName: Methods, type: EnvironmentType = .Dev) -> String {
    
    switch methodName{
    case .GetImage:
        return "/drs/quest"
    case .AdBlock:
        return "/drs/saveAdBlockInfo"
    case .GetHcpValidation:
        return "/dop/getHcpSelfValidation"
    case .UpdateHcpValidation:
        return "/dop/updateHcpSelfValidation"
    case .PatientSession:
        return "/drs/nEvent"
    case .AppConfig:
        return "/dop/settings?version=1"
    }
}
