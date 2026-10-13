import Foundation

/// After force-kill, send deferred engagement (eType=5) on next SDK start (RN `recoverOrphanedAdEngagement` parity).
enum OrphanedAdEngagementRecovery {
    static func recover() {
        guard let snapshot = ActiveAdRecoveryStore.load() else { return }

        // Clear first so a crash mid-recover cannot loop forever.
        ActiveAdRecoveryStore.clear()

        let now = Int64(Date().timeIntervalSince1970 * 1000)
        if now - snapshot.updatedAt > ActiveAdRecoveryStore.maxAgeMs {
            DocereeLog.debug("Orphaned ad snapshot expired; dropping without send")
            return
        }

        guard let url = makeRecoveryEngagementURL(from: snapshot) else { return }

        DocereeBeaconQueue.sendViewabilityURLOrEnqueue(url)
        DocereeLog.debug("Recovered orphaned ad engagement after app kill / unclean exit")
    }

    static func makeRecoveryEngagementURL(from snapshot: ActiveAdRecoveryStore.Snapshot) -> String? {
        guard !snapshot.adViewedURL.isEmpty, snapshot.totalViewTime > 0 else { return nil }

        let viewedPercentage: Int = snapshot.oneSecMrcSent
            ? 50
            : max(Int(snapshot.savedViewPercentage.rounded(.down)), 50)

        return AdViewedURLPopulator.populate(
            url: snapshot.adViewedURL,
            viewedTime: snapshot.totalViewTime,
            viewedPercentage: viewedPercentage,
            standard: "mrc",
            adViewed: false
        )
    }
}
