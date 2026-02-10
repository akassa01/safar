import Foundation
import os

enum Log {
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.safar", category: "data")
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.safar", category: "ui")
    static let auth = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.safar", category: "auth")
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.safar", category: "network")
    static let cache = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.safar", category: "cache")
}
