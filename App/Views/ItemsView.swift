import SwiftUI

/// Use views to see a list of all Items, add or delete Items, or logout.
struct ItemsView: View {
    @Binding var showMyItems: Bool
    @Binding var isInOfflineMode: Bool
    var leadingBarButton: AnyView?
    
    @EnvironmentObject var errorHandler: ErrorHandler
    @EnvironmentObject var viewModel: ItemsViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if viewModel.isInCreateItemView {
                        CreateItemView(isInCreateItemView: $viewModel.isInCreateItemView)
                    }
                    else {
                        Toggle("Show Only My Tasks", isOn: $showMyItems).padding()
                        ItemList()
                    }
                }
                .navigationBarItems(leading: self.leadingBarButton,
                                    trailing: HStack {
                    Button {
                        if !isInOfflineMode {
                            viewModel.showOfflineNote = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                viewModel.showOfflineNote = false
                            }
                        }
                        isInOfflineMode = !isInOfflineMode
                        
                    } label: {
                        isInOfflineMode ? Image(systemName: "wifi.slash") : Image(systemName: "wifi")
                    }
                    Button {
                        viewModel.isInCreateItemView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                })
                .overlay(alignment: .top) {
                    Color.clear // Or any view or color
                        .background(.regularMaterial) // I put clear here because I prefer to put a blur in this case. This modifier and the material it contains are optional.
                        .ignoresSafeArea(edges: .top)
                        .frame(height: 0) // This will constrain the overlay to only go above the top safe area and not under.
                }
                if viewModel.showOfflineNote {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundColor(Color(UIColor.lightGray))
                        .frame(width: 250, height: 150, alignment: .bottom)
                        .overlay(
                            VStack {
                                Text("Now 'Offline'").font(.largeTitle)
                                Text("Switching mode not affect query data when sync is offline").font(.body)
                            }
                                .padding()
                                .multilineTextAlignment(.center)
                            
                        )
                }
            }
        }
    }

}
