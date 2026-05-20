//
//  AnalyticsManager.swift
//  Safar
//

import Foundation
import PostHog

final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private init() {}

    func configure() {
        let apiKey = Bundle.main.infoDictionary?["POSTHOG_API_KEY"] as? String ?? ""
        let config = PostHogConfig(apiKey: apiKey, host: "https://us.i.posthog.com")
        config.sessionReplay = true
        config.sessionReplayConfig.maskAllTextInputs = true
        config.sessionReplayConfig.maskAllImages = false
        PostHogSDK.shared.setup(config)
    }

    func identify(userId: String, username: String?) {
        var properties: [String: Any] = [:]
        if let username = username { properties["username"] = username }
        PostHogSDK.shared.identify(userId, userProperties: properties)
    }

    func reset() {
        PostHogSDK.shared.reset()
    }

    func capture(_ event: String, properties: [String: Any] = [:]) {
        PostHogSDK.shared.capture(event, properties: properties)
    }
}
