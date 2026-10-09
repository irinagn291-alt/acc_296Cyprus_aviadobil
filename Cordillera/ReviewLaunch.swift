import Foundation

/// Live screenshot driver: `-ReviewScreen today|log|goals` (plus extra cover keys).
/// Read `ReviewLaunch.screen` once, after onboarding is done, and open that
/// screen. Keep this file; the navigation it drives belongs to the app.
enum ReviewLaunch {
    static let argument = "-ReviewScreen"

    /// The key after `-ReviewScreen`, or nil on a normal launch.
    static var screen: String? {
        screen(in: ProcessInfo.processInfo.arguments)
    }

    /// Parses launch arguments. A value that itself looks like a flag is ignored.
    static func screen(in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: argument), index + 1 < arguments.count else {
            return nil
        }
        let value = arguments[index + 1]
        if value.hasPrefix("-") {
            return nil
        }
        return value
    }
}
