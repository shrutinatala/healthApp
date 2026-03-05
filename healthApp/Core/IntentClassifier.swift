//
//  IntentClassifier.swift
//  Health_BLOCKFEATURE
//
//  Pure data model + keyword-matching algorithm.
//  No ScreenTime or FamilyControls APIs used here.
//

import SwiftUI

// MARK: - AppEntry

/// Represents an app that should be enabled (or a representative blocked app)
struct AppEntry: Identifiable, Equatable {
    let id: UUID
    let name: String
    let subtitle: String
    let symbolName: String
    let symbolColor: Color

    init(name: String, subtitle: String, symbolName: String, symbolColor: Color) {
        self.id = UUID()
        self.name = name
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.symbolColor = symbolColor
    }
}

// MARK: - IntentCategory

enum IntentCategory: String, CaseIterable {
    case communication
    case productivity
    case creativity
    case news
    case health
    case finance
    case navigation
    case education
    case entertainment
    case social
    case unknown

    var displayName: String {
        switch self {
        case .communication:  return "Communication"
        case .productivity:   return "Productivity"
        case .creativity:     return "Creativity"
        case .news:           return "News & Info"
        case .health:         return "Health & Wellness"
        case .finance:        return "Finance"
        case .navigation:     return "Navigation"
        case .education:      return "Education"
        case .entertainment:  return "Entertainment"
        case .social:         return "Social Media"
        case .unknown:        return "General"
        }
    }

    var badgeColor: Color {
        switch self {
        case .communication:  return .blue
        case .productivity:   return .orange
        case .creativity:     return .purple
        case .news:           return .red
        case .health:         return .green
        case .finance:        return Color(.systemGray)
        case .navigation:     return .teal
        case .education:      return .indigo
        case .entertainment:  return .pink
        case .social:         return .cyan
        case .unknown:        return Color(.systemGray2)
        }
    }
}

// MARK: - ClassificationResult

struct ClassificationResult {
    let intentText: String
    let category: IntentCategory
    let enabledApps: [AppEntry]
    let blockedApps: [AppEntry]
    let confidence: Double               // 0.0 – 1.0
    let matchedKeywords: [String]        // keywords that triggered the result
    let allCategoryScores: [IntentCategory: Int]   // scores for ALL categories
    let runnerUpCategory: IntentCategory?           // 2nd-best if score >= 50% of winner
}

// MARK: - UserCustomizationsData

/// Lightweight snapshot of user customizations passed into the classifier.
struct UserCustomizationsData {
    let extraKeywords: [String: [String]]    // category rawValue → extra keywords
    let extraApps: [String: [AppEntry]]      // category rawValue → extra AppEntry items
}

// MARK: - IntentClassifier

struct IntentClassifier {

    // MARK: Keyword maps

    private static let keywordMap: [IntentCategory: [String]] = [
        .communication: [
            "email", "mail", "gmail", "message", "text", "reply", "send",
            "inbox", "compose", "contact", "write to", "reach out", "call",
            "facetime", "phone", "letter", "dm", "respond", "chat",
            "reach someone", "write back", "check inbox", "voice call", "video call"
        ],
        .productivity: [
            "work", "task", "project", "meeting", "plan", "schedule",
            "document", "report", "presentation", "draft", "type",
            "reminder", "todo", "deadline", "spreadsheet", "office",
            "agenda", "write", "get things done", "check off", "block time",
            "wrap up", "focus on work"
        ],
        .creativity: [
            "photo", "video", "edit", "create", "design", "draw", "paint",
            "sketch", "film", "record", "art", "camera", "podcast", "logo",
            "illustration", "graphic", "animate", "compose music"
        ],
        .news: [
            "news", "article", "browse", "research", "headlines", "discover",
            "update", "latest", "find out", "look up", "search",
            "current events", "information"
        ],
        .health: [
            "workout", "exercise", "run", "gym", "fitness", "walk",
            "meditate", "sleep", "breathe", "yoga", "health", "steps",
            "calories", "nutrition", "water", "diet", "mindfulness",
            "jog", "bike", "swim", "stretch",
            "go for a run", "hit the gym", "track steps", "drink water", "breathing"
        ],
        .finance: [
            "bank", "money", "pay", "payment", "budget", "invest",
            "transfer", "bill", "expense", "finance", "wallet",
            "transaction", "savings", "stock", "crypto", "purchase",
            "spend", "account", "loan"
        ],
        .navigation: [
            "drive", "navigate", "directions", "map", "travel",
            "route", "commute", "airport", "flight", "trip",
            "destination", "location", "get to", "find", "go to",
            "transit", "bus", "train"
        ],
        .education: [
            "study", "learn", "course", "class", "school", "homework",
            "textbook", "lecture", "quiz", "exam", "practice", "language",
            "math", "science", "history", "tutorial", "assignment", "read a book",
            "brush up on", "look something up", "read about", "take notes"
        ],
        .entertainment: [
            "watch", "movie", "show", "netflix", "youtube", "episode",
            "film", "stream", "relax", "tv", "series", "anime",
            "binge", "chill", "fun", "game", "play", "entertain",
            "kick back", "watch something", "unwind", "something funny"
        ],
        .social: [
            "instagram", "twitter", "tiktok", "snapchat", "reddit",
            "facebook", "post", "story", "scroll", "follow", "like",
            "social", "chat with friends", "feed", "viral",
            "trending", "reels", "tweet", "meme",
            "check feed", "see what's happening", "scroll through", "catch up with"
        ]
    ]

    // MARK: App registries

    private static let appMap: [IntentCategory: [AppEntry]] = [
        .communication: [
            AppEntry(name: "Mail",     subtitle: "Email & Messaging", symbolName: "envelope.fill",         symbolColor: .blue),
            AppEntry(name: "Messages", subtitle: "Text Messages",     symbolName: "message.fill",          symbolColor: .green),
            AppEntry(name: "FaceTime", subtitle: "Video Calls",       symbolName: "video.fill",            symbolColor: .green),
            AppEntry(name: "Notes",    subtitle: "Draft & Write",     symbolName: "note.text",             symbolColor: .orange),
            AppEntry(name: "Safari",   subtitle: "Web Mail",          symbolName: "safari",                symbolColor: .blue)
        ],
        .productivity: [
            AppEntry(name: "Calendar",  subtitle: "Scheduling",         symbolName: "calendar",               symbolColor: .red),
            AppEntry(name: "Reminders", subtitle: "Task Lists",         symbolName: "checkmark.circle.fill",  symbolColor: .red),
            AppEntry(name: "Notes",     subtitle: "Writing & Docs",     symbolName: "note.text",              symbolColor: .orange),
            AppEntry(name: "Files",     subtitle: "Documents",          symbolName: "folder.fill",            symbolColor: .blue),
            AppEntry(name: "Safari",    subtitle: "Web Research",       symbolName: "safari",                 symbolColor: .blue)
        ],
        .creativity: [
            AppEntry(name: "Photos",  subtitle: "Photos & Videos",   symbolName: "photo.fill",     symbolColor: .indigo),
            AppEntry(name: "Camera",  subtitle: "Take Photos",        symbolName: "camera.fill",    symbolColor: Color(.systemGray)),
            AppEntry(name: "Music",   subtitle: "Audio",              symbolName: "music.note",     symbolColor: .pink),
            AppEntry(name: "Files",   subtitle: "Creative Assets",    symbolName: "folder.fill",    symbolColor: .blue),
            AppEntry(name: "Safari",  subtitle: "Web Resources",      symbolName: "safari",         symbolColor: .blue)
        ],
        .news: [
            AppEntry(name: "Safari",   subtitle: "Web Browser",     symbolName: "safari",                  symbolColor: .blue),
            AppEntry(name: "News",     subtitle: "News Articles",    symbolName: "newspaper.fill",           symbolColor: .red),
            AppEntry(name: "Podcasts", subtitle: "Audio Content",    symbolName: "waveform.circle.fill",     symbolColor: .purple)
        ],
        .health: [
            AppEntry(name: "Health",  subtitle: "Health Tracking",     symbolName: "heart.fill",    symbolColor: .red),
            AppEntry(name: "Fitness", subtitle: "Exercise & Workouts", symbolName: "figure.run",    symbolColor: .orange),
            AppEntry(name: "Clock",   subtitle: "Timers & Alarms",     symbolName: "clock.fill",    symbolColor: .blue)
        ],
        .finance: [
            AppEntry(name: "Wallet",     subtitle: "Payments",       symbolName: "wallet.pass.fill",       symbolColor: Color(.systemGray)),
            AppEntry(name: "Calculator", subtitle: "Calculations",   symbolName: "plus.forwardslash.minus", symbolColor: Color(.systemGray)),
            AppEntry(name: "Safari",     subtitle: "Online Banking",  symbolName: "safari",                 symbolColor: .blue)
        ],
        .navigation: [
            AppEntry(name: "Maps",   subtitle: "Navigation & Directions", symbolName: "map.fill",    symbolColor: .green),
            AppEntry(name: "Clock",  subtitle: "Timers & Alarms",         symbolName: "clock.fill",  symbolColor: .blue),
            AppEntry(name: "Safari", subtitle: "Travel Research",          symbolName: "safari",      symbolColor: .blue)
        ],
        .education: [
            AppEntry(name: "Notes",    subtitle: "Study Notes",      symbolName: "note.text",             symbolColor: .orange),
            AppEntry(name: "Safari",   subtitle: "Research",          symbolName: "safari",                symbolColor: .blue),
            AppEntry(name: "Books",    subtitle: "Reading",           symbolName: "book.fill",             symbolColor: .orange),
            AppEntry(name: "Podcasts", subtitle: "Learning Audio",    symbolName: "waveform.circle.fill",  symbolColor: .purple)
        ],
        .entertainment: [
            AppEntry(name: "Photos", subtitle: "Local Videos",   symbolName: "photo.fill",   symbolColor: .indigo),
            AppEntry(name: "Music",  subtitle: "Music Player",    symbolName: "music.note",   symbolColor: .pink),
            AppEntry(name: "Safari", subtitle: "Streaming",        symbolName: "safari",       symbolColor: .blue)
        ],
        .social: [
            AppEntry(name: "Messages", subtitle: "Text Messages", symbolName: "message.fill",  symbolColor: .green),
            AppEntry(name: "FaceTime", subtitle: "Video Calls",   symbolName: "video.fill",    symbolColor: .green),
            AppEntry(name: "Photos",   subtitle: "Share Moments", symbolName: "photo.fill",    symbolColor: .indigo)
        ],
        .unknown: [
            AppEntry(name: "Notes",     subtitle: "Writing & Docs", symbolName: "note.text",             symbolColor: .orange),
            AppEntry(name: "Safari",    subtitle: "Web Browser",     symbolName: "safari",                symbolColor: .blue),
            AppEntry(name: "Calendar",  subtitle: "Scheduling",      symbolName: "calendar",              symbolColor: .red),
            AppEntry(name: "Reminders", subtitle: "Task Lists",      symbolName: "checkmark.circle.fill", symbolColor: .red)
        ]
    ]

    private static let defaultBlockedApps: [AppEntry] = [
        AppEntry(name: "Social Media", subtitle: "Distracting Apps", symbolName: "hand.raised.fill",      symbolColor: .red),
        AppEntry(name: "Games",        subtitle: "Gaming Apps",       symbolName: "gamecontroller.fill",   symbolColor: .purple)
    ]

    // MARK: - Jaro-Winkler Similarity

    /// Returns the Jaro-Winkler similarity between two strings (0.0–1.0).
    /// Higher values mean more similar. Used to catch typos in user input.
    private func jaroWinkler(_ a: String, _ b: String) -> Double {
        let s1 = Array(a), s2 = Array(b)
        let len1 = s1.count, len2 = s2.count
        guard len1 > 0 && len2 > 0 else { return len1 == len2 ? 1.0 : 0.0 }

        let matchWindow = max(0, max(len1, len2) / 2 - 1)
        var s1Matched = [Bool](repeating: false, count: len1)
        var s2Matched = [Bool](repeating: false, count: len2)
        var matches = 0.0
        var transpositions = 0.0

        for i in 0..<len1 {
            let start = max(0, i - matchWindow)
            let end = min(i + matchWindow + 1, len2)
            guard start < end else { continue }
            for j in start..<end where !s2Matched[j] {
                if s1[i] == s2[j] {
                    s1Matched[i] = true
                    s2Matched[j] = true
                    matches += 1
                    break
                }
            }
        }
        guard matches > 0 else { return 0.0 }

        var k = 0
        for i in 0..<len1 where s1Matched[i] {
            while k < s2Matched.count && !s2Matched[k] { k += 1 }
            guard k < s2Matched.count else { break }
            if s1[i] != s2[k] { transpositions += 1 }
            k += 1
        }

        let jaro = (matches / Double(len1) + matches / Double(len2) + (matches - transpositions / 2) / matches) / 3.0

        // Winkler prefix bonus (up to 4 chars)
        var prefix = 0
        for i in 0..<min(4, min(len1, len2)) where s1[i] == s2[i] {
            prefix += 1
        }
        return jaro + Double(prefix) * 0.1 * (1.0 - jaro)
    }

    /// Returns true if any word in the input fuzzy-matches any word in the keyword phrase.
    /// Threshold 0.88 is tuned for short words to avoid false positives.
    private func fuzzyMatches(inputWords: [String], keyword: String) -> Bool {
        let keywordWords = keyword.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count >= 3 }
        for iw in inputWords where iw.count >= 3 {
            for kw in keywordWords {
                if jaroWinkler(iw, kw) >= 0.88 { return true }
            }
        }
        return false
    }

    // MARK: - classify (convenience)

    /// Classifies free-form intent text. Convenience wrapper with no customizations.
    func classify(_ text: String) -> ClassificationResult {
        return classify(text, customizations: nil)
    }

    // MARK: - classify (primary)

    /// Classifies free-form intent text and returns a result describing
    /// which apps should be enabled. No ScreenTime APIs are called.
    ///
    /// - Parameters:
    ///   - text: The raw user intent string.
    ///   - customizations: Optional extra keywords and apps to inject per category.
    func classify(_ text: String, customizations: UserCustomizationsData? = nil) -> ClassificationResult {
        let lowercased = text.lowercased()

        // Build allCategoryScores with zeros for every category upfront
        var allScores: [IntentCategory: Int] = Dictionary(
            uniqueKeysWithValues: IntentCategory.allCases.map { ($0, 0) }
        )

        guard !lowercased.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ClassificationResult(
                intentText: text,
                category: .unknown,
                enabledApps: Self.appMap[.unknown]!,
                blockedApps: Self.defaultBlockedApps,
                confidence: 0.0,
                matchedKeywords: [],
                allCategoryScores: allScores,
                runnerUpCategory: nil
            )
        }

        // Pre-compute input words for fuzzy matching
        let inputWords = lowercased
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }

        // Single-pass scoring: exact phrase match (1.0 pt) or fuzzy word match (0.6 pt)
        var matchedKeywordsByCategory: [IntentCategory: [String]] = [:]
        var fractionalScores: [IntentCategory: Double] = [:]

        for category in IntentCategory.allCases where category != .unknown {
            var keywords = Self.keywordMap[category] ?? []
            if let custom = customizations?.extraKeywords[category.rawValue] {
                keywords += custom
            }

            var score = 0.0
            var matched: [String] = []

            for keyword in keywords {
                let keywordLower = keyword.lowercased()
                if lowercased.contains(keywordLower) {
                    score += 1.0
                    matched.append(keyword)
                } else if fuzzyMatches(inputWords: inputWords, keyword: keywordLower) {
                    score += 0.6
                    matched.append(keyword)
                }
            }

            fractionalScores[category] = score
            matchedKeywordsByCategory[category] = matched
            allScores[category] = Int(score.rounded())
        }

        let winnerEntry = fractionalScores.max(by: { $0.value < $1.value })
        let winnerScore = winnerEntry?.value ?? 0.0

        guard winnerScore > 0, let winner = winnerEntry?.key else {
            return ClassificationResult(
                intentText: text,
                category: .unknown,
                enabledApps: Self.appMap[.unknown]!,
                blockedApps: Self.defaultBlockedApps,
                confidence: 0.0,
                matchedKeywords: [],
                allCategoryScores: allScores,
                runnerUpCategory: nil
            )
        }

        // Compute confidence
        let totalScore = fractionalScores.values.reduce(0.0, +)
        let dominance = totalScore > 0 ? winnerScore / totalScore : 0.0

        // Find runner-up score
        let sortedScores = fractionalScores.sorted(by: { $0.value > $1.value })
        let runnerUpScore: Double = sortedScores.count > 1 ? sortedScores[1].value : 0.0
        let margin = winnerScore > 0 ? (winnerScore - runnerUpScore) / winnerScore : 0.0

        let confidence = min(1.0, (dominance + margin) / 2.0)

        // Determine runner-up category
        var runnerUpCategory: IntentCategory? = nil
        if sortedScores.count > 1 {
            let candidate = sortedScores[1]
            if candidate.value >= winnerScore * 0.5 && candidate.key != winner {
                runnerUpCategory = candidate.key
            }
        }

        // Collect matched keywords for the winner
        let matchedKeywords = matchedKeywordsByCategory[winner] ?? []

        // Build enabled apps, merging custom apps if provided
        var enabledApps = Self.appMap[winner] ?? Self.appMap[.unknown]!
        if let customApps = customizations?.extraApps[winner.rawValue] {
            for customApp in customApps {
                if !enabledApps.contains(where: { $0.name == customApp.name }) {
                    enabledApps.append(customApp)
                }
            }
        }

        // Social intents show no "also blocked" — social IS the goal
        let blocked = winner == .social ? [] : Self.defaultBlockedApps

        return ClassificationResult(
            intentText: text,
            category: winner,
            enabledApps: enabledApps,
            blockedApps: blocked,
            confidence: confidence,
            matchedKeywords: matchedKeywords,
            allCategoryScores: allScores,
            runnerUpCategory: runnerUpCategory
        )
    }
}
