//
//  BlockingView.swift
//  Health_BLOCKFEATURE
//
//  In-app preview of the system shield screen shown when a blocked app is opened.
//  The actual blocking is handled by ShieldConfigurationExtension on device.
//

import SwiftUI

private let sagePrimary = Color(red: 0.40, green: 0.63, blue: 0.47)
private let sageDeep    = Color(red: 0.22, green: 0.45, blue: 0.33)

/// Preview of the shield screen shown when a blocked app is opened.
struct BlockingView: View {
    let appName: String

    @Environment(\.dismiss) private var dismiss
    @State private var motivationalMessage: String = ""

    private static let messages = [
        "Stay focused on what matters.",
        "You're doing great — keep going.",
        "Time to focus on your goals.",
        "Your future self will thank you.",
        "Take a mindful moment instead.",
        "This can wait. Your intention cannot."
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Dismiss button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(20)
            }
            .zIndex(1)

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(sagePrimary.opacity(0.12))
                        .frame(width: 140, height: 140)

                    Image(systemName: "hand.raised.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [sagePrimary, sageDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.bottom, 28)

                Text("App Blocked")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(sageDeep)
                    .padding(.bottom, 8)

                Text(appName)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)

                Text(motivationalMessage)
                    .font(.headline)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 48)

                Spacer()
                Spacer()

                VStack(spacing: 12) {
                    Button("OK") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(sagePrimary)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                    Button("Take a 5-min break instead") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .tint(sagePrimary)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 32)

                // Info footer
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("This is a preview of the system shield screen that blocked apps would display.")
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            motivationalMessage = Self.messages.randomElement() ?? Self.messages[0]
        }
    }
}

#Preview {
    BlockingView(appName: "Social Media")
}
