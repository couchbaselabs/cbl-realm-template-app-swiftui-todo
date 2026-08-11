import SwiftUI

struct ItemRow: View {
    var item: Item
    
    var body: some View {
        NavigationLink(destination: ItemDetail(item: item)) {
            Text(item.summary)
            Spacer()
            if item.isComplete == true {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .padding(.trailing, 10)
            }
            if item.ownerId == app.currentUser?.username {
                Text("(mine)")
            }
        }
    }
}
