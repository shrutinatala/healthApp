//
//  UserCustomizations.swift
//  Health_BLOCKFEATURE
//
//  Persists user-defined keywords, app lists, and custom categories.
//

import SwiftUI
import Combine

// MARK: - CustomAppEntry

/// A user-editable app entry (simpler than AppEntry, fully Codable).
struct CustomAppEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var subtitle: String
    var symbolName: String   // SF Symbol name
    var colorHex: String     // hex string e.g. "007AFF"
    var isBlockedEntry: Bool // true = goes in "blocked" list, false = goes in "enabled" list
}

// MARK: - CustomCategory

/// A fully user-defined intent category.
struct CustomCategory: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
    var keywords: [String]
    var apps: [CustomAppEntry]
}

// MARK: - UserCustomizations

@MainActor
class UserCustomizations: ObservableObject {
    static let shared = UserCustomizations()

    /// Extra keywords per built-in category (keyed by IntentCategory.rawValue).
    @Published var extraKeywords: [String: [String]] = [:] {
        didSet { save() }
    }

    /// Extra app entries per built-in category (keyed by IntentCategory.rawValue).
    @Published var extraApps: [String: [CustomAppEntry]] = [:] {
        didSet { save() }
    }

    /// Fully custom categories defined by the user.
    @Published var customCategories: [CustomCategory] = [] {
        didSet { save() }
    }

    private let defaultsKey = "UserCustomizations_v1"

    init() {
        load()
    }

    // MARK: - Persistence

    private func save() {
        let snapshot = Snapshot(
            extraKeywords: extraKeywords,
            extraApps: extraApps,
            customCategories: customCategories
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        extraKeywords = snapshot.extraKeywords
        extraApps = snapshot.extraApps
        customCategories = snapshot.customCategories
    }

    /// Codable snapshot for persistence.
    private struct Snapshot: Codable {
        var extraKeywords: [String: [String]]
        var extraApps: [String: [CustomAppEntry]]
        var customCategories: [CustomCategory]
    }

    // MARK: - Keyword Helpers

    /// Adds a trimmed, lowercased keyword to the given built-in category.
    /// Duplicate and empty keywords are silently ignored.
    func addKeyword(_ keyword: String, to category: IntentCategory) {
        let key = category.rawValue
        var list = extraKeywords[key] ?? []
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, !list.contains(trimmed) else { return }
        list.append(trimmed)
        extraKeywords[key] = list
    }

    /// Removes the specified keyword from the given built-in category.
    func removeKeyword(_ keyword: String, from category: IntentCategory) {
        let key = category.rawValue
        extraKeywords[key]?.removeAll { $0 == keyword }
    }

    /// Returns all extra keywords for the given built-in category.
    func keywords(for category: IntentCategory) -> [String] {
        extraKeywords[category.rawValue] ?? []
    }

    // MARK: - App Helpers

    /// Appends a custom app entry to the given built-in category.
    func addApp(_ app: CustomAppEntry, to category: IntentCategory) {
        let key = category.rawValue
        var list = extraApps[key] ?? []
        list.append(app)
        extraApps[key] = list
    }

    /// Removes the custom app with the given id from the given built-in category.
    func removeApp(id: UUID, from category: IntentCategory) {
        let key = category.rawValue
        extraApps[key]?.removeAll { $0.id == id }
    }

    /// Returns all custom app entries for the given built-in category.
    func apps(for category: IntentCategory) -> [CustomAppEntry] {
        extraApps[category.rawValue] ?? []
    }
}

// MARK: - Preview

#Preview {
    // Simple preview demonstrating the model compiles correctly.
    Text("UserCustomizations model loaded")
        .task {
            let uc = UserCustomizations()
            uc.addKeyword("yoga", to: .health)
            uc.addApp(
                CustomAppEntry(
                    name: "Streaks",
                    subtitle: "Habit Tracker",
                    symbolName: "flame.fill",
                    colorHex: "FF9500",
                    isBlockedEntry: false
                ),
                to: .health
            )
        }
}
