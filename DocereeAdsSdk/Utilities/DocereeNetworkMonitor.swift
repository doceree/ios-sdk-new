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

    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let satisfied = path.status == .satisfied
            if satisfied, !self.pathSatisfied {
                DocereeLog.debug("Network path satisfied — flushing beacon queue")
                DocereeBeaconQueue.flushQueue()
            }
            self.pathSatisfied = satisfied
        }
        monitor.start(queue: queue)
    }
}
