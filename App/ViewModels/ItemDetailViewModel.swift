import Foundation

@MainActor
class ItemDetailViewModel : ObservableObject {
    let service: DatabaseService
    
    init(_ service:DatabaseService) {
        self.service = service
    }
    
    func updateItem(item: Item, isComplete:Bool, newSummary: String) async {
        await service.updateItem(item: item, isComplete: isComplete, summary: newSummary)
    }
}
