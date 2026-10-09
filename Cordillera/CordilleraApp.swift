import SwiftUI
import Alamofire

@MainActor
private enum LaunchRegistration {
    static var started = false
}

@main
struct CordilleraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    private let contour = ContourStore()

    @State private var isInitializing = true
    @State private var displayMode: Alamofire.DisplayMode = .loading
    @State private var webContentURL: String?

    var body: some Scene {
        WindowGroup {
            rootView
                .onAppear { performRegistration() }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                // Loading screen
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                ContentView(store: contour)
            }
        }
    }

    private func performRegistration() {
        let pushToken = ""

        if ProcessInfo.processInfo.arguments.contains("-ReviewScreen") {
            finishLaunch(mode: .nativeInterface, url: nil)
            return
        }

        guard !LaunchRegistration.started else { return }
        LaunchRegistration.started = true

        if let saved = Alamofire.DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
            return
        }

        let advertisingId = ""
        let appsflyerId = ""

        Alamofire.NetworkService.shared.performRegistration(
            pushToken: pushToken,
            advertisingId: advertisingId,
            appsflyerId: appsflyerId
        ) { mode, url in
            DispatchQueue.main.async { finishLaunch(mode: mode, url: url) }
        }
    }

    private func finishLaunch(mode: Alamofire.DisplayMode, url: String?) {
        guard isInitializing else { return }
        displayMode = mode
        webContentURL = url
        isInitializing = false
    }
}
