import SwiftUI

struct ContentView: View {
    let store: ContourStore

    var body: some View {
        ProfileRoot(store: store)
            .ignoresSafeArea()
    }
}

/// Hosts the UIKit elevation profile. The canvas stays up for the session.
private struct ProfileRoot: UIViewControllerRepresentable {
    let store: ContourStore

    func makeUIViewController(context: Context) -> ProfileViewController {
        ProfileViewController(store: store)
    }

    func updateUIViewController(_ uiViewController: ProfileViewController, context: Context) {}
}

#Preview {
    ContentView(store: ContourStore())
}
