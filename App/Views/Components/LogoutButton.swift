import SwiftUI

/// Logout from the synchronized realm. Returns the user to the login/sign up screen.
struct LogoutButton: View {
    @EnvironmentObject var viewModel: LogoutViewModel
    var body: some View {
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
