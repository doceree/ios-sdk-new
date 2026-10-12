import Foundation

/// Builds fired `adViewedURL` pixels with Viewed (eType=2) vs Engagement (eType=5). React Native `populateAdViewedUrl` parity.
enum AdViewedURLPopulator {
    static func populate(
        url: String,
        viewedTime: Int,
        viewedPercentage: Int,
        standard: String,
        adViewed: Bool,
        eventClientTime: String = Date.currentTimeMillis()
    ) -> String {
        var result = url
            .replacingOccurrences(of: "{{EVENT_CLIENT_TIME}}", with: eventClientTime)
            .replacingOccurrences(of: "{{VIEWED_TIME}}", with: String(viewedTime))
            .replacingOccurrences(of: "{{VIEWED_PERCENTAGE}}", with: String(viewedPercentage))
            .replacingOccurrences(of: "_std", with: standard)

        if !adViewed {
            result = result.replacingOccurrences(of: "eType=2", with: "eType=5")
        }

        return result
    }

    static func eventType(from adViewed: Bool) -> Int {
        adViewed ? 2 : 5
    }
}
