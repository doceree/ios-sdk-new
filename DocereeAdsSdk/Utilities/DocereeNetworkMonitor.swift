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
                Task {
                    guard await DocereeNetworkReachability.isNetworkAvailable() else {
                        DocereeLog.debug("Network path up but ad host unreachable — deferring beacon flush")
                        return
                    }
                    DocereeLog.debug("Network restored — flushing beacon queue")
                    await DocereeBeaconQueue.flushQueueAndWait()
                }
            }
            self.pathSatisfied = satisfied
        }
        monitor.start(queue: queue)
    }
}
