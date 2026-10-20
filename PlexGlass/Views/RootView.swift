import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        if appModel.session.isAuthenticated {
            LibraryRootView()
        } else {
            LoginView()
        }
    }
}
