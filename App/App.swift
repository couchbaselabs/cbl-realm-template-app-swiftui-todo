import SwiftUI

let appConfig = loadAppConfig()
let app = CBLApp(configuration: appConfig)

@main
struct todoSwiftUIApp: SwiftUI.App {
    @StateObject var errorHandler = ErrorHandler(app: app)
    private let service = { return DatabaseService() }()
    
    var body: some Scene {
        WindowGroup {
            ContentView(app: app)
                .environmentObject(CreateItemViewModel(service))
                .environmentObject(errorHandler)
                .environmentObject(ItemDetailViewModel(service))
                .environmentObject(ItemsViewModel(service))
                .environmentObject(LoginViewModel(service))
                .environmentObject(LogoutViewModel(service))
                .environmentObject(OpenDatabaseViewModel(service))
                .alert(Text("Error"), isPresented: .constant(errorHandler.error != nil)) {
                    Button("OK", role: .cancel) { errorHandler.error = nil }
                } message: {
                    Text(errorHandler.error?.localizedDescription ?? "")
                }
        }
    }
}

final class ErrorHandler: ObservableObject {
    @Published var error: Swift.Error?

    init(app: CBLApp) {
    }
}
