import SwiftUI

struct CreateItemView: View {
    @EnvironmentObject var viewModel:CreateItemViewModel
    
    // We've passed in the ``creatingNewItem`` variable
    // from the ItemsView to know when the user is done
    // with the new Item and we should return to the ItemsView.
    @Binding var isInCreateItemView: Bool

    var body: some View {
        Form {
            Section(header: Text("Item Name")) {
                TextField("New item", text: $viewModel.itemSummary)
            }
            Section {
                Button(action: {
                    // To avoid updating too many times and causing Sync-related
                    // performance issues, we only assign to the `newItem.summary`
                    // once when the user presses `Save`.
                    Task {
                        await viewModel.createItem()
                    }
                    
                    // Now we're done with this view, so set the
                    // ``isInCreateItemView`` variable to false to
                    // return to the ItemsView.
                    isInCreateItemView = false
                    
                }) {
                    HStack {
                        Spacer()
                        Text("Save")
                        Spacer()
                    }
                }
                Button(action: {
                    // If the user cancels, we don't want to
                    // append the new object we created to the
                    // task list, so we set the ``isInCreateItemView``
                    // value to false to return to the ItemsView.
                    isInCreateItemView = false
                }) {
                    HStack {
                        Spacer()
                        Text("Cancel")
                        Spacer()
                    }
                }
            }
        }
        .navigationBarTitle("Add Item")
    }
}
