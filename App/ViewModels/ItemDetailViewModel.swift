import Foundation
import Observation

/// Holds no state of its own, but must still be `@Observable`: `@Environment`
/// can only resolve objects whose type conforms to `Observable`.
@Observable
@MainActor
class ItemDetailViewModel {
    let service: DatabaseService

    init(_ service:DatabaseService) {
        self.service = service
    }

    func updateItem(item: Item, isComplete:Bool, newSummary: String) async {
        await service.updateItem(item: item, isComplete: isComplete, summary: newSummary)
    }
}
