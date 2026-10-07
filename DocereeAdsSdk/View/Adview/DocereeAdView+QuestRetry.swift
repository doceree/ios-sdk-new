import Foundation
import ObjectiveC
import UIKit

extension DocereeAdView {
    var lastAdFetchSize: String? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.lastAdFetchSize) as? String }
        set { objc_setAssociatedObject(self, &AssociatedKeys.lastAdFetchSize, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }

    var lastAdFetchUserId: String? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.lastAdFetchUserId) as? String }
        set { objc_setAssociatedObject(self, &AssociatedKeys.lastAdFetchUserId, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }

    private var questOnlineRetryCount: Int {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.questOnlineRetryCount) as? Int) ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.questOnlineRetryCount, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var questRetryWorkItem: DispatchWorkItem? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.questRetryWorkItem) as? DispatchWorkItem }
        set { objc_setAssociatedObject(self, &AssociatedKeys.questRetryWorkItem, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var networkPollTimer: Timer? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.networkPollTimer) as? Timer }
        set { objc_setAssociatedObject(self, &AssociatedKeys.networkPollTimer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var waitingForNetwork: Bool {
        get { (objc_getAssociatedObject(self, &AssociatedKeys.waitingForNetwork) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &AssociatedKeys.waitingForNetwork, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func resetQuestRetries() {
        questOnlineRetryCount = 0
        stopQuestRetry()
    }

    func stopQuestRetry() {
        questRetryWorkItem?.cancel()
        questRetryWorkItem = nil
    }

    func stopNetworkPoll() {
        networkPollTimer?.invalidate()
        networkPollTimer = nil
        waitingForNetwork = false
    }

    func stopAdNetworkRecovery() {
        stopNetworkPoll()
        stopQuestRetry()
    }

    func retryAdLoadIfPossible() {
        guard let size = lastAdFetchSize, let userId = lastAdFetchUserId else { return }
        fetchAd(size, userId)
    }

    func handleAdRequestFailure(_ error: Error) {
        DocereeLog.debug("Ad request failed: \(error.localizedDescription)")

        Task { @MainActor in
            guard self.window != nil else { return }

            if !(await DocereeNetworkReachability.isNetworkAvailable()) {
                DocereeLog.debug("Quest failed offline — waiting for network")
                scheduleReloadWhenOnline()
                return
            }

            if self.questOnlineRetryCount >= DocereeAdQuestRetry.maxOnlineAttempts {
                DocereeLog.debug("Quest online retries exhausted; waiting for next refresh cycle")
                return
            }

            self.questOnlineRetryCount += 1
            let delayMs = DocereeAdQuestRetry.delayMs(forAttempt: self.questOnlineRetryCount)
            DocereeLog.debug(
                "Retrying quest in \(delayMs)ms (attempt \(self.questOnlineRetryCount)/\(DocereeAdQuestRetry.maxOnlineAttempts))"
            )
            self.stopQuestRetry()
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                DocereeBeaconQueue.flushQueue()
                self.retryAdLoadIfPossible()
            }
            self.questRetryWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delayMs) / 1000, execute: work)
        }
    }

    private func scheduleReloadWhenOnline() {
        guard !waitingForNetwork else { return }
        stopQuestRetry()
        waitingForNetwork = true
        DocereeLog.debug("Skipping ad refresh until network is available")
        networkPollTimer?.invalidate()
        networkPollTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            Task {
                guard await DocereeNetworkReachability.isNetworkAvailable() else { return }
                await MainActor.run {
                    timer.invalidate()
                    self.stopNetworkPoll()
                    self.resetQuestRetries()
                    DocereeBeaconQueue.flushQueue()
                    self.retryAdLoadIfPossible()
                }
            }
        }
    }
}

private enum AssociatedKeys {
    static var lastAdFetchSize: UInt8 = 0
    static var lastAdFetchUserId: UInt8 = 0
    static var questOnlineRetryCount: UInt8 = 0
    static var questRetryWorkItem: UInt8 = 0
    static var networkPollTimer: UInt8 = 0
    static var waitingForNetwork: UInt8 = 0
}
