import SwiftUI

/// Logout from the synchronized realm. Returns the user to the login/sign up screen.
struct LogoutButton: View {
    @Environment(LogoutViewModel.self) private var viewModel

    var body: some View {
        // `@Bindable` is what makes `$viewModel.errorMessage` available for an
        // `@Observable` object resolved from the environment.
        @Bindable var viewModel = viewModel

        // Declaring the shadow above makes this a normal function body rather than
        // an implicit `ViewBuilder` one, so the two views are grouped explicitly.
        return Group {
            if viewModel.isLoggingOut {
                ProgressView()
            }
            Button("Log Out") {
                viewModel.isLoggingOut = true
                Task {
                    logout()
                }
            }.disabled(app.currentUser == nil || viewModel.isLoggingOut)
            // Show an alert if there is an error during logout
                .alert(item: $viewModel.errorMessage) { errorMessage in
                Alert(
                    title: Text("Failed to log out"),
                    message: Text(errorMessage.errorText),
                    dismissButton: .cancel()
                )
            }
        }
    }

    // log the user out, or display an alert with an error if logout fails.
    func logout() {
        Task{
            await viewModel.logout()
        }
    }
}

struct ErrorMessage: Identifiable {
    let id = UUID()
    let errorText: String
}
