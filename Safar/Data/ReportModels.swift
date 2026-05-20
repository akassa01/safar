//
//  ReportModels.swift
//  Safar
//
//  Enums for content reporting and user blocking.
//

import Foundation

enum ReportType: String, Codable {
    case post = "post"
    case comment = "comment"
    case user = "user"

    var displayName: String {
        switch self {
        case .post: return "post"
        case .comment: return "comment"
        case .user: return "user"
        }
    }
}

enum ReportReason: String, Codable, CaseIterable, Identifiable {
    case spam = "spam"
    case harassment = "harassment"
    case inappropriateContent = "inappropriate_content"
    case hateSpeech = "hate_speech"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment"
        case .inappropriateContent: return "Inappropriate Content"
        case .hateSpeech: return "Hate Speech"
        case .other: return "Other"
        }
    }
}
