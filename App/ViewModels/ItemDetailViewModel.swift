import Foundation

class ItemDetailViewModel : ObservableObject {
    let service: DatabaseService
    
    init(_ service:DatabaseService) {
        self.service = service
    }
    
    func toggleIsComplete(item: Item, value: Bool){
        Task {
            await service.toggleIsComplete(item: item, value: value)
        }
    }
}
