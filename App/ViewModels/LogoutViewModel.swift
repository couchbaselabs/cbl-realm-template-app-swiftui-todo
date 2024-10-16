import Foundation

@MainActor
class LogoutViewModel : ObservableObject {
    var isLoggingOut = false
    var errorMessage: ErrorMessage? = nil
    var error: Error?
    let service: DatabaseService
    
    init(_ service:DatabaseService) {
        self.service = service
    }
    
    func logout() async {
        await service.close()
        app.currentUser = nil
        self.isLoggingOut =  false
    }
}
