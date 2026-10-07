import Foundation

/// Best-effort reachability check against the ad host (React Native parity).
enum DocereeNetworkReachability {
    private static let probeTimeout: TimeInterval = 2.5

    static func isNetworkAvailable() async -> Bool {
        let host = getHost(type: DocereeMobileAds.shared().getEnvironment())
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = "/"
        guard let url = components.url else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get
        request.timeoutInterval = probeTimeout

        do {
            _ = try await URLSession.shared.data(for: request)
            return true
        } catch {
            DocereeLog.debug("Network unavailable: \(error.localizedDescription)")
            return false
        }
    }
}
