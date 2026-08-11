import Foundation
import Observation

/// Application-wide state.
///
/// `@Observable` replaces `ObservableObject` + `@Published`: every stored `var`
/// is tracked individually, and a view is invalidated only by the properties it
/// actually reads in its `body`. Because tracking is per-property rather than
/// per-object, this works even though `app` is a plain global - views do not need
/// to hold it in a property wrapper to observe it.
@Observable
class CBLApp {
    var currentUser: User? = nil
    var appConfig: AppConfig
    var error: Error? = nil
    var databaseState: DatabaseState = .notInitialized
    
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

