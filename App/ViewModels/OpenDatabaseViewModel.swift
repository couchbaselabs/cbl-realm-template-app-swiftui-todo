import Foundation
import Observation

/// Holds no state of its own, but must still be `@Observable`: `@Environment`
/// can only resolve objects whose type conforms to `Observable`.
@Observable
@MainActor
class OpenDatabaseViewModel {
    let service: DatabaseService

    init(_ service:DatabaseService) {
        self.service = service
    }

    func pauseSync() async {
        await service.pauseSync()
    }

    func resumeSync() async {
        await service.resumeSync()
    }
}
