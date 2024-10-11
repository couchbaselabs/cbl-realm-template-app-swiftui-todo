import SwiftUI

/// Called when login completes. Navigates to the Items screen.
struct OpenDatabaseView: View {
    @ObservedObject var cblApp = app
    
    @EnvironmentObject var itemsViewModel: ItemsViewModel
    @EnvironmentObject var viewModel: OpenDatabaseViewModel

    @State var showMyItems = true
    @State var isInOfflineMode = false
    
    var body: some View {
        switch cblApp.databaseState {
            case .notInitialized,
                    .connecting:
                // Show a progress view.
                ProgressView()
            case .open:
                // The Database is open and ready for use.  Show the Items view.
                ItemsView(
                    showMyItems: $showMyItems,
                    isInOfflineMode: $isInOfflineMode,
                    leadingBarButton: AnyView(LogoutButton()))
                
                // showMyItems toggles the query of myItems
                // When it's toggled on, only the the current users items are shown.
                // When it's toggled off, *all* items are shown, regardless of the user
                    .onChange(of: showMyItems) { newValue in
                        Task {
                            if newValue {
                                await itemsViewModel.setMyItems()
                            } else {
                                await itemsViewModel.setAllItems()
                            }
                        }
                    }
                    .onAppear {
                        Task {
                            await itemsViewModel.setMyItems()
                        }
                    }
                // isInOfflineMode simulates a situation with no internet connection.
                // While sync is not available, items can still be written and queried.
                // When sync is resumed, items created or updated offline will upload to
                // the server and changes from the server or other devices will be downloaded to the client.
                    .onChange(of: isInOfflineMode) { newValue in
                        Task {
                            newValue ? await viewModel.pauseSync() : await viewModel.resumeSync()
                        }
                    }
            case .error(let error):
                // Opening the Realm failed.
                // Show an error view.
                ErrorView(error: error)
        }
    }
}
