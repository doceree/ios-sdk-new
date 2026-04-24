//
//  DocereeSignposts.swift
//  DocereeAdsSdk
//

import Foundation
import os.log

/// `os_signpost` intervals for Instruments (Time Profiler, Points of Interest). No URLs or PII in names.
/// Default: enabled in `DEBUG`, disabled in Release. Toggle via `DocereeMobileAds.isSignpostEnabled`.
internal enum DocereeSignposts {
    internal static let subsystem = "com.doceree.DocereeAdSdk"

    /// When `false`, all signpost begin/end calls are no-ops.
    internal static var isEnabled: Bool = {
//        #if DEBUG
//        return true
//        #else
        return true
//        #endif
    }()

    private static let networkLog = OSLog(subsystem: subsystem, category: "Network")
    private static let adRequestLog = OSLog(subsystem: subsystem, category: "AdRequest")
    private static let configurationLog = OSLog(subsystem: subsystem, category: "Configuration")

    /// Pair `begin`/`end` for one scoped operation. Call `end()` in `defer` so failures still close the interval.
    internal struct Interval {
        private let log: OSLog
        private let name: StaticString
        private let id: OSSignpostID

        fileprivate init(name: StaticString, log: OSLog) {
            self.log = log
            self.name = name
            self.id = OSSignpostID(log: log)
            if DocereeSignposts.isEnabled {
                os_signpost(.begin, log: log, name: name, signpostID: id)
            }
        }

        internal func end() {
            if DocereeSignposts.isEnabled {
                os_signpost(.end, log: log, name: name, signpostID: id)
            }
        }
    }

    internal static func networkInterval(_ name: StaticString) -> Interval {
        Interval(name: name, log: networkLog)
    }

    internal static func adRequestInterval(_ name: StaticString) -> Interval {
        Interval(name: name, log: adRequestLog)
    }

    internal static func configurationInterval(_ name: StaticString) -> Interval {
        Interval(name: name, log: configurationLog)
    }
}
