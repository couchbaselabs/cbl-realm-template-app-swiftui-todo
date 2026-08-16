import Observation
import SwiftUI

let appConfig = loadAppConfig()
let app = CBLApp(configuration: appConfig)

@main
struct todoSwiftUIApp: SwiftUI.App {
    @State private var errorHandler = ErrorHandler(app: app)
    private let service = { return DatabaseService() }()

    var body: some Scene {
        WindowGroup {
            ContentView(app: app)
                .environment(CreateItemViewModel(service))
                .environment(errorHandler)
                .environment(ItemDetailViewModel(service))
                .environment(ItemsViewModel(service))
                .environment(LoginViewModel(service))
                .environment(LogoutViewModel(service))
                .environment(OpenDatabaseViewModel(service))
                .alert(Text("Error"), isPresented: .constant(errorHandler.error != nil)) {
                    Button("OK", role: .cancel) { errorHandler.error = nil }
                } message: {
                    Text(errorHandler.error?.localizedDescription ?? "")
                }
        }
    }
}

@Observable
final class ErrorHandler {
    var error: Swift.Error?

    init(app: CBLApp) {
    }
}
