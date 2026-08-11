import Combine
import CouchbaseLiteSwift
import Foundation
import Observation

@Observable
@MainActor
class ItemsViewModel {
    var items: [Item] = []
    var isInCreateItemView = false
    var showOfflineNote = false

    let service: DatabaseService

    /// Holds the live query subscription. Releasing the `AnyCancellable` cancels the
    /// underlying query listener, so there is no token to remove by hand.
    ///
    /// Marked `@ObservationIgnored` because this is replication plumbing, not view
    /// state - without it, storing a subscription would invalidate every view that
    /// reads this object.
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    init(_ service: DatabaseService) {
        self.service = service
    }

    func delete(item: Item) async {
        await service.deleteTask(item: item)
    }

    func setAllItems() async {
        await observeTasks(subscriptionType: Constants.allItems)
    }

    func setMyItems() async {
        await observeTasks(subscriptionType: Constants.myItems)
    }

    /// Subscribes to the live query for the given subscription type and keeps
    /// `items` in step with it.
    ///
    /// Any previous subscription is cancelled first, so toggling between "my tasks"
    /// and "all tasks" swaps cleanly rather than leaving two live queries running.
    ///
    /// The publisher delivers on the main queue by default, and emits the *entire*
    /// result set on every change - so `items` is replaced, never appended to.
    private func observeTasks(subscriptionType: String) async {
        cancellables.removeAll()

        guard let query = await service.tasksQuery(
            subscriptionType: subscriptionType)
        else { return }

        query.changePublisher()
            .map { change -> [Item] in
                guard let results = change.results else { return [] }
                return (try? results.data(as: Item.self)) ?? []
            }
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
    }
}
