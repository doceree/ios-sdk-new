import Foundation

/// Local connectivity only (`NWPathMonitor`) — no HTTP probe to the ad host.
enum DocereeNetworkReachability {
    static func isNetworkAvailable() async -> Bool {
        DocereeNetworkMonitor.shared.isPathSatisfied()
    }
}
