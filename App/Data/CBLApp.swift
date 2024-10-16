import Foundation

class CBLApp: ObservableObject {
    @Published var currentUser: User? = nil
    @Published var appConfig: AppConfig
    @Published var error: Error? = nil
    @Published var databaseState: DatabaseState = .notInitialized
    
    init(configuration: AppConfig){
        appConfig = configuration
    }
    
    func setCurrentUser(_ user: User?){
        DispatchQueue.main.sync {
            self.currentUser = user
        }
    }
    
    func setError(_ error: Error?){
        DispatchQueue.main.sync {
            self.error = error
        }
    }
    
    func setDatabaseState(_ state: DatabaseState){
        DispatchQueue.main.sync {
            self.databaseState = state
        }
    }
}

struct ConnectionException: Error {
    let message: String
}

struct InvalidCredentialsException: Error {
    let message: String
}

struct ApplicationUserIsNil: Error {
    let message: String
}

struct InvalidEndpointUrl: Error {
    let message: String
}

struct InvalidStateError: Error {
    let message: String
}

