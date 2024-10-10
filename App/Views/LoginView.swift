import SwiftUI

/// Log in or register users using email/password authentication
struct LoginView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    @EnvironmentObject var errorHandler: ErrorHandler

    var body: some View {
        VStack {
            if viewModel.isLoggingIn {
                ProgressView()
            }
            VStack {
                Text("Couchbase Mobile App")
                    .font(.title)
                    .onTapGesture(count: 2) {
                        // This block is executed on double click
                        viewModel.setDefaultUsernamePassword()
                    }
                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled(true)
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                Button("Log In") {
                    // Button pressed, so log in
                    Task.init {
                        await login()
                    }
                }
                .disabled(viewModel.isLoggingIn)
                .frame(width: 150, height: 50)
                .background(Color(red: 234/255, green: 35/255, blue: 40/255))
                .foregroundColor(.white)
                .clipShape(Capsule())
                Text("Please log in with Capella App Endpoint user account. This is separate from your Capella login")
                    .font(.footnote)
                    .padding(20)
                    .multilineTextAlignment(.center)
            }.padding(20)
        }
    }

    /// Logs in with an existing user.
    func login() async {
        do {
            try await viewModel.login()
            print("Successfully logged in user: \(app.currentUser?.username ?? "unknown")")
        } catch {
            print("Failed to log in user: \(error.localizedDescription)")
            errorHandler.error = error
        }
    }
}
