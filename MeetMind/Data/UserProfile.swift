import Foundation

// MARK: - UserProfile

struct UserProfile: Codable {
    var role: WorkRole
    var roleDescription: String
    var meetingTools: [MeetingTool]
    var meetingFrequency: MeetingFrequency
    var onboardingComplete: Bool

    init(
        role: WorkRole = .other,
        roleDescription: String = "",
        meetingTools: [MeetingTool] = [],
        meetingFrequency: MeetingFrequency = .moderate,
        onboardingComplete: Bool = false
    ) {
        self.role = role
        self.roleDescription = roleDescription
        self.meetingTools = meetingTools
        self.meetingFrequency = meetingFrequency
        self.onboardingComplete = onboardingComplete
    }

    /// Context string injected into AI prompts for personalized summaries
    var aiContextString: String {
        var parts: [String] = []
        parts.append("The user is a \(role.displayName)")
        if !roleDescription.isEmpty {
            parts.append("who describes their work as: \(roleDescription)")
        }
        if !meetingTools.isEmpty {
            let toolNames = meetingTools.map(\.displayName).joined(separator: ", ")
            parts.append("They primarily use \(toolNames) for meetings")
        }
        parts.append("and have meetings \(meetingFrequency.displayName)")
        return parts.joined(separator: ". ") + "."
    }
}

// MARK: - WorkRole

enum WorkRole: String, Codable, CaseIterable {
    case consulting
    case engineering
    case sales
    case product
    case executive
    case design
    case dataScience
    case other

    var displayName: String {
        switch self {
        case .consulting:  return "Consultant"
        case .engineering:  return "Engineer"
        case .sales:        return "Sales Professional"
        case .product:      return "Product Manager"
        case .executive:    return "Executive / Leadership"
        case .design:       return "Designer"
        case .dataScience:  return "Data Scientist"
        case .other:        return "Other"
        }
    }

    var icon: String {
        switch self {
        case .consulting:  return "briefcase.fill"
        case .engineering:  return "wrench.and.screwdriver.fill"
        case .sales:        return "chart.line.uptrend.xyaxis"
        case .product:      return "square.grid.2x2.fill"
        case .executive:    return "crown.fill"
        case .design:       return "paintbrush.fill"
        case .dataScience:  return "chart.bar.fill"
        case .other:        return "person.fill"
        }
    }
}

// MARK: - MeetingTool

enum MeetingTool: String, Codable, CaseIterable {
    case teams
    case googleMeet
    case zoom
    case slack
    case webex

    var displayName: String {
        switch self {
        case .teams:      return "Microsoft Teams"
        case .googleMeet: return "Google Meet"
        case .zoom:       return "Zoom"
        case .slack:      return "Slack"
        case .webex:      return "Webex"
        }
    }

    var icon: String {
        switch self {
        case .teams:      return "person.3.fill"
        case .googleMeet: return "video.fill"
        case .zoom:       return "video.circle.fill"
        case .slack:      return "number"
        case .webex:      return "phone.circle.fill"
        }
    }
}

// MARK: - MeetingFrequency

enum MeetingFrequency: String, Codable, CaseIterable {
    case daily
    case frequent    // 3-5 per week
    case moderate    // 1-2 per week
    case occasional  // a few per month

    var displayName: String {
        switch self {
        case .daily:      return "daily"
        case .frequent:   return "3-5 times per week"
        case .moderate:   return "1-2 times per week"
        case .occasional: return "a few times per month"
        }
    }
}

// MARK: - UserProfile Persistence

extension UserProfile {
    private static let storageKey = "meetmind_user_profile"

    static func load() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return profile
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: UserProfile.storageKey)
        }
    }
}
