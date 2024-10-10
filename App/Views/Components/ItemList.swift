import SwiftUI

/// view a list of all Items in the collection. User can swipe to delete Items.
struct ItemList: View {
    @EnvironmentObject var viewModel: ItemsViewModel
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.items) { item in
                    ItemRow(item: item)
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(InsetListStyle())
            Spacer()
            Text("Log in or create a different account on another device or simulator to see your list sync in real time")
                .frame(maxWidth: 300, alignment: .center)
            Spacer()
        }
        .navigationBarTitle("Items", displayMode: .inline)
    }
    
    func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { viewModel.items[$0] }
        for item in itemsToDelete {
            Task {
                await viewModel.delete(item: item)
            }
        }
    }
}
