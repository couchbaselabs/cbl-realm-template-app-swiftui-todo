import SwiftUI

/// View a list of all Items in the collection. User can swipe to delete their own Items.
struct ItemList: View {
    @Environment(ItemsViewModel.self) private var viewModel
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.items) { item in
                    ItemRow(item: item)
                        // `.onDelete` on the `ForEach` would offer swipe-to-delete on every
                        // row uniformly - there is no per-row way to opt out of it. Using
                        // `.swipeActions` per row instead means the delete button (and the
                        // swipe gesture) only exists on rows the current user owns; other
                        // rows have no swipe action at all, matching the "owner only" rule
                        // `ItemDetail` already enforces for editing.
                        .swipeActions(edge: .trailing) {
                            if app.currentUser?.username == item.ownerId {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.delete(item: item)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                }
            }
            .listStyle(InsetListStyle())
            Spacer()
            Text("Log in on another device or simulator to see your list sync in real time")
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(.regularMaterial)
            Spacer()
        }
        .navigationBarTitle("Items", displayMode: .inline)
    }
}
