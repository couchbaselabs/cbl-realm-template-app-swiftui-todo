import Foundation

@MainActor
class CreateItemViewModel: ObservableObject {
    @Published var itemSummary = ""

    let service: DatabaseService

    init(_ service: DatabaseService) {
        self.service = service
    }

    func createItem() async {
        await service.addTask(taskSummary: itemSummary)
        //reset summary for next creation
        self.itemSummary = ""
    }
}
