import Foundation

class OpenDatabaseViewModel : ObservableObject {
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
