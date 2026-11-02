import Foundation
import Network

/// Observes connectivity and flushes the beacon queue when the path becomes reachable again.
final class DocereeNetworkMonitor {
    static let shared = DocereeNetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "doceree.network.path")
    private var started = false
    private var pathSatisfied = true

    private init() {}

    /// Whether the device has a usable network path (Wi‑Fi/cellular). Does not hit the ad server.
    func isPathSatisfied() -> Bool {
        if !started {
            return true
        }
        return monitor.currentPath.status == .satisfied
    }

    func start() {
        guard !started else { return }
        started = true
        pathSatisfied = monitor.currentPath.status == .satisfied
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let satisfied = path.status == .satisfied
            if satisfied, !self.pathSatisfied {
                Task {
                    DocereeLog.debug("Network restored — flushing beacon queue")
                    await DocereeBeaconQueue.flushQueueAndWait()
                }
            }
            self.pathSatisfied = satisfied
        }
        monitor.start(queue: queue)
    }
}
