import Foundation

class ItemsViewModel : ObservableObject {
    @Published var items: [Item] = []
    let service: DatabaseService
    
    init(_ service:DatabaseService) {
        self.service = service
    }
    
    func delete (item: Item) async {
        await service.deleteTask(item: item)
    }
    
    func setAllItems() async {
        await service.setTasksListChangeObserver(
            subscriptionType: Constants.allItems,
            observer: updateItems)
    }
    
    func setMyItems() async {
        await service.setTasksListChangeObserver(
            subscriptionType: Constants.myItems,
            observer: updateItems)
    }
    
    func updateItems(newItems: [Item]?) {
        DispatchQueue.main.async {
            self.items.removeAll()
            if let nis = newItems {
                self.items.append(contentsOf: nis)
            }
        }
    }
    
}
