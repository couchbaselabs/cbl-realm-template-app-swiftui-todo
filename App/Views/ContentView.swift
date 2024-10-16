import SwiftUI

struct ContentView: View {
    @EnvironmentObject var errorHandler: ErrorHandler
    @EnvironmentObject var viewModel: ItemsViewModel
    
    @ObservedObject var app: CBLApp

    var body: some View {
        if app.currentUser != nil {
            OpenDatabaseView()
                .environmentObject(errorHandler)
                .environmentObject(viewModel)
        } else {
            // If there is no user logged in, show the login view.
            LoginView()
        }
    }
}
