import Foundation

/// Simulator-only opening pack. One active hold, several trig marks, pin ready.
enum DemoSeed {
    static let key = "cdr.demo.v1"
    static let onboardingKey = "cdr.onboarding.complete"

    static func installIfNeeded(store: ContourStore) async {
        #if targetEnvironment(simulator)
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: key) == false else { return }
        let today = SurveyDay.stamp(Date())
        let summit = SurveyDay.adding(days: 14, to: today)
        do {
            let finished = try await store.moor(title: "The Living Mountain", isbn: "9780857861832", totalPages: 160, on: today)
            _ = try await store.open(holdID: finished.id, on: today, plannedSummitDay: today)
            _ = try await store.pin(pages: 160, on: today)
            let active = try await store.moor(title: "Annapurna", isbn: "9780141185381", totalPages: 320, on: today)
            _ = try await store.open(holdID: active.id, on: today, plannedSummitDay: summit)
            _ = try await store.pin(pages: 24, on: today)
            _ = try await store.pin(pages: 18, on: today)
            _ = try await store.pin(pages: 12, on: today)
            _ = try await store.moor(title: "The Snow Leopard", isbn: "9780140255089", totalPages: 352, on: today)
            _ = try await store.moor(title: "Into Thin Air", isbn: "9780385494786", totalPages: 416, on: today)
            await store.flush()
            defaults.set(true, forKey: key)
            defaults.set(true, forKey: onboardingKey)
        } catch {
            // Leave the seed key unset so the next launch can try again.
            return
        }
        #endif
    }
}
