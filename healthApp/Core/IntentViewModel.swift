//
//  IntentViewModel.swift
//  Health_BLOCKFEATURE
//

import Combine
import Foundation

@MainActor
class IntentViewModel: ObservableObject {
    @Published var intentText: String = ""
    @Published var result: ClassificationResult? = nil
    @Published var hasSubmitted: Bool = false
    @Published var liveResult: ClassificationResult? = nil

    private var debounceTask: Task<Void, Never>? = nil

    var isSubmittable: Bool {
        !intentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func submit() {
        result = IntentClassifier().classify(intentText)
        hasSubmitted = true
    }

    func reset() {
        intentText = ""
        result = nil
        hasSubmitted = false
        liveResult = nil
        debounceTask?.cancel()
        debounceTask = nil
    }

    /// Updates `liveResult` with a debounced classification as the user types.
    /// Cancels any in-flight debounce when called again before the 250 ms window elapses.
    func updateLive(_ text: String) {
        debounceTask?.cancel()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            liveResult = nil
            return
        }
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000) // 250 ms
            guard !Task.isCancelled else { return }
            let r = IntentClassifier().classify(text)
            await MainActor.run {
                self.liveResult = r.confidence > 0 ? r : nil
            }
        }
    }
}
