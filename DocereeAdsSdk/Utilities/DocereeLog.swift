import Foundation

/// Internal debug logging for SDK development. No output in non-DEBUG builds.
enum DocereeLog {
    static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[DocereeAdsSdk]", message())
        #endif
    }
}
