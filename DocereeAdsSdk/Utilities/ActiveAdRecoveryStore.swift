import Foundation

/// Persist in-flight ad viewing so engagement can be sent on next launch after a force-kill (RN `ActiveAdRecoveryStore` parity).
enum ActiveAdRecoveryStore {
    static let snapshotKey = "docereeActiveAdSnapshot"
    static let maxAgeMs: Int64 = 24 * 60 * 60 * 1000

    struct Snapshot: Codable, Equatable {
        let adViewedURL: String
        let totalViewTime: Int
        let savedViewPercentage: Double
        let oneSecMrcSent: Bool
        let updatedAt: Int64
    }

    static func mark(
        adViewedURL: String,
        totalViewTime: Int,
        savedViewPercentage: Double,
        oneSecMrcSent: Bool,
        updatedAt: Int64? = nil
    ) {
        guard !adViewedURL.isEmpty, totalViewTime > 0 else { return }
        let payload = Snapshot(
            adViewedURL: adViewedURL,
            totalViewTime: totalViewTime,
            savedViewPercentage: savedViewPercentage,
            oneSecMrcSent: oneSecMrcSent,
            updatedAt: updatedAt ?? Int64(Date().timeIntervalSince1970 * 1000)
        )
        do {
            let object: [String: Any] = [
                "adViewedURL": payload.adViewedURL,
                "totalViewTime": payload.totalViewTime,
                "savedViewPercentage": DocereeDecimalPrecision.jsonNormalizedNumber(from: payload.savedViewPercentage),
                "oneSecMrcSent": payload.oneSecMrcSent,
                "updatedAt": payload.updatedAt
            ]
            let data = try DocereeDecimalPrecision.jsonData(withJSONObject: object)
            UserDefaults.standard.set(data, forKey: snapshotKey)
        } catch {
            DocereeLog.debug("markActiveAdSnapshot failed: \(error.localizedDescription)")
        }
    }

    static func load() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: snapshotKey) else { return nil }
        do {
            let parsed = try JSONDecoder().decode(Snapshot.self, from: data)
            guard !parsed.adViewedURL.isEmpty, parsed.totalViewTime > 0 else { return nil }
            return parsed
        } catch {
            return nil
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: snapshotKey)
    }
}
