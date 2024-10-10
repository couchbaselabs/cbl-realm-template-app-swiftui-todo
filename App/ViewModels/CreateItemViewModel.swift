import Foundation

class CreateItemViewModel : ObservableObject {
    let service: DatabaseService
    
    init(_ service:DatabaseService) {
        self.service = service
    }
    
    func createItem(taskSummary: String){
        Task {
            await service.addTask(taskSummary: taskSummary)
        }
    }
}
