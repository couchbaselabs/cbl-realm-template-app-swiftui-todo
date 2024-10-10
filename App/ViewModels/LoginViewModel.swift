import Foundation

class LoginViewModel : ObservableObject {
    let service: DatabaseService
    
    @Published var email = ""
    @Published var password = ""
    @Published var isLoggingIn = false
    
    init(_ service:DatabaseService) {
        self.service = service
    }
    
    func setDefaultUsernamePassword() {
        email = "demo1@example.com"
        password = "P@ssw0rd12"
    }
    
    func login() async throws  {
        do {
            DispatchQueue.main.async {
                self.isLoggingIn = true
            }
            let user = try await AuthenticationService
                .shared
                .login(username: email, password: password)
            if let loggedInUser = user {
                await service.initializeDatabase(user: loggedInUser)
            }
            DispatchQueue.main.async {
                app.currentUser = user
                self.isLoggingIn = false
            }
        } catch {
            isLoggingIn = false
            throw error
        }
    }
    
}
