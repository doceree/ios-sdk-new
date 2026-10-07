import Foundation

/// Online `/drs/quest` failure backoff (React Native `AdQuestRetry` parity).
enum DocereeAdQuestRetry {
    static let maxOnlineAttempts = 5
    private static let baseDelayMs: Int64 = 5_000
    private static let maxDelayMs: Int64 = 60_000

    static func delayMs(forAttempt attempt: Int) -> Int64 {
        let exponent = max(0, attempt - 1)
        let scaled = baseDelayMs * Int64(1 << min(exponent, 10))
        return min(maxDelayMs, scaled)
    }
}
