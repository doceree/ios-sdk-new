import Foundation
import os

/// Internal debug logging for SDK development. No output in non-DEBUG builds.
/// Uses `Logger` so Xcode console filtering by subsystem/category works.
private final class DocereeLogBundleLocator {}

enum DocereeLog {
    private static let subsystem = Bundle(for: DocereeLogBundleLocator.self).bundleIdentifier ?? "DocereeAdsSdk"
    private static let logger = Logger(subsystem: subsystem, category: "SDK")

    static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        let text = message()
        logger.debug("\(text, privacy: .public)")
        #endif
    }
}
