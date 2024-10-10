import SwiftUI

/// Use views to see a list of all Items, add or delete Items, or logout.
struct ItemsView: View {
    @State var user: User
    @Binding var showMyItems: Bool
    @Binding var isInOfflineMode: Bool
    var leadingBarButton: AnyView?
    
    @State var itemSummary = ""
    @State var isInCreateItemView = false
    @State var showOfflineNote = false
    
    @EnvironmentObject var errorHandler: ErrorHandler
    @EnvironmentObject var viewModel: ItemsViewModel
    
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if isInCreateItemView {
                        CreateItemView(isInCreateItemView: $isInCreateItemView, user: user)
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
                            showOfflineNote = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                self.showOfflineNote = false
                            }
                        }
                        isInOfflineMode = !isInOfflineMode
                        
                    } label: {
                        isInOfflineMode ? Image(systemName: "wifi.slash") : Image(systemName: "wifi")
                    }
                    Button {
                        isInCreateItemView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                })
                if showOfflineNote {
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
