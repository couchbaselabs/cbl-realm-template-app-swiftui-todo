import SwiftUI

struct ContentView: View {
    @Environment(ErrorHandler.self) private var errorHandler
    @Environment(ItemsViewModel.self) private var viewModel

    let app: CBLApp

    var body: some View {
        if app.currentUser != nil {
            OpenDatabaseView()
                .environment(errorHandler)
                .environment(viewModel)
        } else {
            // If there is no user logged in, show the login view.
            LoginView()
        }
    }
}
