//
//  ContentView.swift
//  Health_BLOCKFEATURE
//
//  Main intention-entry screen. Users type their intention for the day,
//  then the app suggests which apps to open.
//  Includes live prediction chip, gear toolbar for customization, and
//  animated transitions for the live classification result.
//

import SwiftUI

// MARK: - Palette

private let sagePrimary  = Color(red: 0.40, green: 0.63, blue: 0.47)
private let sageDeep     = Color(red: 0.22, green: 0.45, blue: 0.33)

struct ContentView: View {
    @StateObject private var viewModel = IntentViewModel()

    @State private var showingCustomization = false

    private let quickExamples = [
        "Send an email",
        "Read the news",
        "Go for a walk",
        "Call a friend",
        "Study something new",
        "Edit some photos"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    intentEditorSection

                    // Live prediction chip — animates in/out below the editor
                    if let live = viewModel.liveResult {
                        LivePredictionChip(result: live)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    submitButton
                    quickExamplesSection
                    Spacer(minLength: 32)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            // Keep the navigation bar transparent so the custom header stays
            // visually primary, while still allowing toolbar items to appear.
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCustomization = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(sageDeep)
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.hasSubmitted) {
                IntentResultsView(viewModel: viewModel)
            }
            // Trigger live classification as user types
            .onChange(of: viewModel.intentText) { _, newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.updateLive(newValue)
                }
            }
            .sheet(isPresented: $showingCustomization) {
                CustomizationView(customizations: UserCustomizations.shared)
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(sagePrimary.opacity(0.15))
                    .frame(width: 110, height: 110)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [sagePrimary, sageDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 36)

            Text("Intentions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text("What is your intention for today?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    private var intentEditorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set your intention")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal)

            ZStack(alignment: .topLeading) {
                if viewModel.intentText.isEmpty {
                    Text("e.g. \"I intend to write a few emails today\"")
                        .foregroundStyle(.tertiary)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.intentText)
                    .frame(minHeight: 110)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .scrollContentBackground(.hidden)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(sagePrimary.opacity(0.4), lineWidth: 1.5)
            )
            .padding(.horizontal)
        }
    }

    private var submitButton: some View {
        Button {
            viewModel.submit()
        } label: {
            HStack(spacing: 8) {
                Text("Set My Intention")
                    .font(.headline)
                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .tint(sagePrimary)
        .controlSize(.large)
        .disabled(!viewModel.isSubmittable)
        .padding(.horizontal)
    }

    private var quickExamplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Or try a quick example")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(quickExamples, id: \.self) { example in
                    QuickExampleChip(label: example, color: sagePrimary) {
                        viewModel.intentText = example
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - LivePredictionChip

/// Compact inline chip that previews the live classification as the user types.
/// Shows the top category badge and a mini confidence bar.
private struct LivePredictionChip: View {
    let result: ClassificationResult

    var body: some View {
        HStack(spacing: 10) {
            // Category label
            Text(result.category.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(sagePrimary)
                .clipShape(Capsule())

            // Mini confidence bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(sagePrimary.opacity(0.6))
                        .frame(width: geo.size.width * result.confidence)
                }
            }
            .frame(height: 6)

            // Percentage label
            Text("\(Int(result.confidence * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(minWidth: 28, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(sagePrimary.opacity(0.35), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: result.confidence)
    }
}

// MARK: - QuickExampleChip

private struct QuickExampleChip: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(color)
        .clipShape(Capsule())
    }
}


#Preview {
    ContentView()
}
