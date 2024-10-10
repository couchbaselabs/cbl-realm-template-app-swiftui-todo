import Foundation

class CBLApp: ObservableObject {
    @Published var currentUser: User? = nil
    @Published var appConfig: AppConfig
    @Published var error: Error? = nil
    @Published var databaseState: DatabaseState = .notInitialized
    
    init(configuration: AppConfig){
        self.appConfig = configuration
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

