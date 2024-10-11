import Foundation

class CreateItemViewModel : ObservableObject {
    @Published var itemSummary = ""
    
    let service: DatabaseService
    
    init(_ service:DatabaseService) {
        self.service = service
    }
    
    func createItem(){
        Task {
            await service.addTask(taskSummary: itemSummary)
            //reset summary for next creation
            DispatchQueue.main.async {
                self.itemSummary = ""
            }
        }
    }
}
