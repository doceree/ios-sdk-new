//
//  DocereeAdView+ViewabilityCycle.swift
//  DocereeAdsSdk
//

import UIKit

private enum ViewabilityCycle {
    static let durationSeconds: TimeInterval = 30
}

extension DocereeAdView {

    func isViewabilityCycleComplete() -> Bool {
        guard let startedAt = viewabilityCycleStartedAt else { return false }
        return Date().timeIntervalSince(startedAt) >= ViewabilityCycle.durationSeconds
    }

    func beginViewabilityCycleIfNeeded(reset: Bool) {
        if reset {
            viewabilityCycleStartedAt = Date()
            refreshPendingAfterCycle = false
            stopPendingRefreshPoll()
        } else if viewabilityCycleStartedAt == nil, !refreshPendingAfterCycle {
            viewabilityCycleStartedAt = Date()
        }
    }

    func isApplicationActiveForViewability() -> Bool {
        UIApplication.shared.applicationState == .active
    }

    /// Cycle-end beacon only while still in view; background or below 50% → engagement already sent on exit.
    func shouldSendCycleEndViewabilityBeacon() -> Bool {
        isApplicationActiveForViewability() && checkViewability(adView: self) >= 50
    }

    func stopMeasurementSessionIfNeeded() {
        sessionInteractor?.stopSession()
    }

    func clearAdResourcesAfterCycleEnd() {
        ActiveAdRecoveryStore.clear()
        adFetchTask?.cancel()
        adFetchTask = nil
        removeAllViews()
    }

    func onViewabilityCycleComplete(reason: String) {
        customTimer?.stop()
        viewabilityCycleStartedAt = nil

        if shouldSendCycleEndViewabilityBeacon() {
            sendViewTime(standard: "mrc", killSession: true, adViewed: false)
        } else {
            stopMeasurementSessionIfNeeded()
            DocereeLog.debug(
                "30s cycle done — skip viewability beacon (inactive or viewport <50%; engagement already sent)"
            )
        }

        clearAdResourcesAfterCycleEnd()
        refreshPendingAfterCycle = true
        tryPerformCycleRefresh(reason: reason)
    }

    /// Fresh ad only when foreground and viewport ≥50%. Cycle may finish in background — clear only until then.
    func tryPerformCycleRefresh(reason: String) {
        guard isApplicationActiveForViewability() else {
            DocereeLog.debug("30s cycle done — cleared; wait for foreground (\(reason))")
            return
        }

        guard checkViewability(adView: self) >= 50 else {
            DocereeLog.debug("30s cycle done — cleared; wait for viewport ≥50% (\(reason))")
            startPendingRefreshPoll()
            return
        }

        refreshPendingAfterCycle = false
        stopPendingRefreshPoll()
        DocereeLog.debug("30s cycle done — loading fresh ad (\(reason))")
        safeRefresh()
    }

    func startPendingRefreshPoll() {
        guard pendingRefreshPollTimer == nil else { return }
        pendingRefreshPollTimer = CustomTimer { [weak self] (_: Int) in
            guard let self else { return }
            guard self.refreshPendingAfterCycle else {
                self.stopPendingRefreshPoll()
                return
            }
            self.tryPerformCycleRefresh(reason: "pending-poll")
        }
        pendingRefreshPollTimer?.start()
    }

    func stopPendingRefreshPoll() {
        pendingRefreshPollTimer?.stop()
        pendingRefreshPollTimer = nil
    }

    func safeRefresh() {
        guard delegate != nil else { return }
        guard !isRefreshing else { return }
        isRefreshing = true
        refresh()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isRefreshing = false
        }
    }
}
