//
//  IntentResultsView.swift
//  Health_BLOCKFEATURE
//
//  Shows the algorithm's output: which apps are enabled for the user's intention,
//  which are representative of what would be blocked, and a shield preview.
//  Includes confidence signal detail, keyword chips, runner-up detection,
//  and a per-category score breakdown chart.
//

import SwiftUI

private let sagePrimary = Color(red: 0.40, green: 0.63, blue: 0.47)
private let sageDeep    = Color(red: 0.22, green: 0.45, blue: 0.33)

struct IntentResultsView: View {
    @ObservedObject var viewModel: IntentViewModel

    @State private var showShieldPreview = false

    private var result: ClassificationResult {
        viewModel.result ?? IntentClassifier().classify("")
    }

    // Whether any category has a non-zero score (determines if score breakdown shows)
    private var hasAnyScore: Bool {
        result.allCategoryScores.values.contains { $0 > 0 }
    }

    var body: some View {
        List {
            // Intention summary card
            Section {
                IntentSummaryCard(result: result)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // Apps that are open
            Section {
                ForEach(result.enabledApps) { app in
                    AppIconTile(entry: app, isBlocked: false)
                }
            } header: {
                Text("Open for You")
            }

            // Score breakdown — only if at least one score > 0
            if hasAnyScore {
                Section {
                    CategoryScoreChart(
                        allCategoryScores: result.allCategoryScores,
                        winner: result.category
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Score Breakdown")
                } footer: {
                    Text("How strongly each category matched your intention")
                }
            }

            // Representative blocked apps (hidden for social intent)
            if !result.blockedApps.isEmpty {
                Section {
                    ForEach(result.blockedApps) { app in
                        AppIconTile(entry: app, isBlocked: true)
                    }
                } header: {
                    Text("Staying Closed")
                } footer: {
                    Text("These categories would be restricted to help you stay focused.")
                }
            }

            // Shield preview
            Section {
                Button {
                    showShieldPreview = true
                } label: {
                    Label("Preview Shield Screen", systemImage: "eye.fill")
                        .font(.headline)
                        .foregroundStyle(sagePrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
                .tint(sagePrimary)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Today's Intention")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShieldPreview) {
            BlockingView(appName: result.blockedApps.first?.name ?? "Social Media")
        }
    }
}

// MARK: - IntentSummaryCard

private struct IntentSummaryCard: View {
    let result: ClassificationResult

    /// Controls the inline confidence explanation popover.
    @State private var showConfidenceInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Intent text + category badge row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your intention")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\"\(result.intentText)\"")
                        .font(.body)
                        .italic()
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }
                Spacer()
                CategoryBadge(category: result.category)
            }

            // Confidence row
            if result.confidence > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: result.confidence)
                        .tint(sagePrimary)

                    HStack(alignment: .center, spacing: 4) {
                        Text("\(Int(result.confidence * 100))% confidence · \(result.matchedKeywords.count) matched signal\(result.matchedKeywords.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Button {
                            showConfidenceInfo.toggle()
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showConfidenceInfo, arrowEdge: .bottom) {
                            Text("Confidence reflects how clearly your intention maps to one category. More matched keywords = higher confidence.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(12)
                                .frame(maxWidth: 220)
                                .presentationCompactAdaptation(.popover)
                        }

                        Spacer()
                    }
                }
            }

            // Matched keyword chips row
            if !result.matchedKeywords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(result.matchedKeywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.caption)
                                .foregroundStyle(sagePrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(sagePrimary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            // Runner-up row
            if let runnerUp = result.runnerUpCategory {
                HStack(spacing: 6) {
                    Text("Also detected:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(runnerUp.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(sagePrimary.opacity(0.3), lineWidth: 1.5)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - CategoryScoreChart

/// Horizontal bar chart showing relative category scores.
/// Only displays categories with score > 0, sorted descending.
private struct CategoryScoreChart: View {
    let allCategoryScores: [IntentCategory: Int]
    let winner: IntentCategory

    private var sortedNonZero: [(category: IntentCategory, score: Int)] {
        allCategoryScores
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { (category: $0.key, score: $0.value) }
    }

    private var maxScore: Int {
        sortedNonZero.first?.score ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sortedNonZero, id: \.category) { entry in
                CategoryScoreRow(
                    category: entry.category,
                    score: entry.score,
                    maxScore: maxScore,
                    isWinner: entry.category == winner
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct CategoryScoreRow: View {
    let category: IntentCategory
    let score: Int
    let maxScore: Int
    let isWinner: Bool

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 8) {
                // Category name — fixed width
                Text(category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 110, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Bar
                let barMaxWidth = geo.size.width - 110 - 8 - 30 - 8
                let fraction = maxScore > 0 ? CGFloat(score) / CGFloat(maxScore) : 0
                Capsule()
                    .fill(isWinner ? sagePrimary : Color(.systemGray4))
                    .frame(width: max(4, barMaxWidth * fraction), height: 8)

                Spacer(minLength: 0)

                // Score number
                Text("\(score)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isWinner ? sagePrimary : .secondary)
                    .frame(width: 24, alignment: .trailing)
            }
        }
        .frame(height: 20)
    }
}

// MARK: - CategoryBadge

private struct CategoryBadge: View {
    let category: IntentCategory

    var body: some View {
        Text(category.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(category.badgeColor)
            .clipShape(Capsule())
    }
}

// MARK: - AppIconTile

private struct AppIconTile: View {
    let entry: AppEntry
    let isBlocked: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isBlocked
                        ? Color(.systemGray5)
                        : entry.symbolColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: entry.symbolName)
                    .font(.system(size: 20))
                    .foregroundStyle(isBlocked ? Color(.systemGray) : entry.symbolColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.body)
                    .foregroundStyle(isBlocked ? .secondary : .primary)
                Text(entry.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: isBlocked ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundStyle(isBlocked ? Color(.systemGray3) : sagePrimary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let vm = IntentViewModel()
    vm.result = IntentClassifier().classify("I want to write an email")
    return NavigationStack {
        IntentResultsView(viewModel: vm)
    }
}
