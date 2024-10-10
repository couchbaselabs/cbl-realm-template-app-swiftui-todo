import SwiftUI

/// Show a detail view of a task Item. User can edit the summary or mark the Item complete.
struct ItemDetail: View {
    @EnvironmentObject var viewModel:ItemDetailViewModel
    
    // This property wrapper observes the Item object and
    // invalidates the view when the Item object changes.
    @State var item: Item
    @State private var isCompleteToggleState: Bool
    
    init (item: Item){
        _item = State(initialValue: item)
        _isCompleteToggleState = State(initialValue: item.isComplete)
    }
    
    var body: some View {
        Form {
            // Only show the "Edit Item Summary" section if the user is the owner
            if app.currentUser?.username == item.ownerId {
                Section(header: Text("Edit Item Summary")) {
                    TextField("Summary", text: $item.summary)
                }
                Section {
                    Toggle(isOn: $isCompleteToggleState) {
                        Text("Complete")
                    }
                    .onChange(of: isCompleteToggleState) { newValue in
                        item.isComplete =  newValue
                        viewModel.toggleIsComplete(item: item, value: newValue)
                    }
                }
            } else {
                // If the user is not the owner, display only the item summary as a read-only field
                Section(header: Text("Item Summary")) {
                    Text(item.summary)
                }
            }
        }
        .navigationBarTitle("Update Item", displayMode: .inline)
    }
}
