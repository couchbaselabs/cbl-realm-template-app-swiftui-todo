import SwiftUI

/// Show a detail view of a task Item. User can edit the summary or mark the Item complete.
struct ItemDetail: View {
    @EnvironmentObject var viewModel:ItemDetailViewModel
    @Environment(\.presentationMode) var presentationMode // Access the presentation mode

    
    // This property wrapper observes the Item object and
    // invalidates the view when the Item object changes.
    @State var item: Item
    @State var summaryText: String
    @State private var isCompleteToggleState: Bool
    
    init (item: Item){
        _summaryText = State(initialValue: item.summary)
        _isCompleteToggleState = State(initialValue: item.isComplete)
        _item = State(initialValue: item)
    }
    
    var body: some View {
        Form {
            // Only show the "Edit Item Summary" section if the user is the owner
            if app.currentUser?.username == item.ownerId {
                Section(header: Text("Edit Item Summary")) {
                    TextField("Summary", text: $summaryText)
                }
                Section {
                    Toggle(isOn: $isCompleteToggleState) {
                        Text("Complete")
                    }
                }
                // Section for the button
                HStack {
                    Spacer()
                    Button("Save") {
                        Task {
                            await viewModel.updateItem(
                                item: item,
                                isComplete: isCompleteToggleState,
                                newSummary: summaryText
                            )
                            // Dismiss the view after the task is completed
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .frame(width: 300)
                    Spacer()
                }
            } else {
                // If the user is not the owner, display only the item summary as a read-only field
                Section(header: Text("Item Summary")) {
                    Text(summaryText)
                }
            }
        }
        .navigationBarTitle("Update Item", displayMode: .inline)
    }
    
}
