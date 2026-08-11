import Combine
import CouchbaseLiteSwift
import Foundation

public enum DatabaseState {
    //database is not initialized
    case notInitialized
    //Starting the Replicator Sync process
    case connecting
    //The database has been opened and is ready for use.
    case open
    //Opening the database or the replicator sync failed
    case error(Error)
}

actor DatabaseService {

    //scope and collection information
    fileprivate let _scopeName = "data"
    fileprivate let _taskCollectionName = "tasks"

    //replicator management
    fileprivate var _replicator: Replicator? = nil

    //Combine subscriptions owned by this service. `AnyCancellable` cancels its
    //subscription when it is released, so there are no listener tokens to remove.
    fileprivate var cancellables = Set<AnyCancellable>()

    //database information
    var database: Database? = nil
    var taskCollection: Collection? = nil

    //cached queries
    var queryMyTasks: Query? = nil
    var queryAllTasks: Query? = nil

    init() {
        //`Database.log` was removed in 4.0. Logging is now configured by
        //assigning a sink to `LogSinks`; `LogSinks.file` can be set the same way
        //to persist logs to disk.
        LogSinks.console = ConsoleLogSink(level: .debug)
    }

    /// Initializes the database for the specified user, sets up collections, indexes, queries, and replication.
    ///
    /// This function creates and configures a database using the sanitized username as the database name. It sets up
    /// the necessary collections, indexes, and queries used for live queries, and initializes the replicator to
    /// sync data with a remote endpoint. The function also manages replication status and updates the app’s
    /// `databaseState` accordingly.
    ///
    /// - Parameter user: The `User` object containing the credentials and username to be used for the database name
    ///   and authentication in the replication process.
    ///
    /// - Important: The function sanitizes the username by replacing certain characters (`@` and `.`) with hyphens (`-`)
    ///   to create a valid database name. Ensure the username is correctly formatted to avoid unexpected errors.
    ///
    /// - Throws: An error if there is an issue opening the database, creating the collection, setting up queries,
    ///   or configuring the replicator.
    ///
    /// - Note: The function updates the app’s `databaseState` to reflect the current status (e.g., `.notInitialized`, `.open`, or `.error`).
    ///   These updates are dispatched on the main thread to ensure UI responsiveness.
    ///
    /// ### Function Behavior:
    /// 1. **Database Initialization**:
    ///    - The function attempts to open or create a database using the sanitized username.
    /// 2. **Collection Setup**:
    ///    - It creates or retrieves a collection named `_taskCollectionName` in the scope `_scopeName`.
    /// 3. **Index Creation**:
    ///    - An index is created on the `"ownerId"` field of the collection for efficient querying.
    /// 4. **Query Setup**:
    ///    - Queries are created for fetching all tasks and tasks belonging to the user using live queries.
    /// 5. **Replicator Configuration**:
    ///    - The replicator is configured with the user’s credentials and an endpoint URL from the app’s configuration.
    ///    - The replicator is set to run continuously, synchronizing data bidirectionally (`pushAndPull`).
    /// 6. **Replication Listener**:
    ///    - A listener monitors the replication status and logs changes, updating the UI state as needed.
    ///
    /// - SeeAlso: `Database`, `Replicator`, `CollectionConfiguration`, `ValueIndexConfiguration`
    func initializeDatabase(user: User) {
        do {

            app.setDatabaseState(.notInitialized)

            //get santised username to use in database name
            let username = user.username
                .replacingOccurrences(of: "@", with: "-")
                .replacingOccurrences(of: ".", with: "-")
            let databaseName = "tasks-\(username)"

            //open database
            self.database = try Database(name: databaseName)
            if let db = self.database {
                //get the collection - create collection with either create a collection
                //or if it already exist, return the existing collection
                self.taskCollection = try db.createCollection(
                    name: _taskCollectionName, scope: _scopeName)
                if let collection = self.taskCollection {
                    //create index
                    let indexConfig = ValueIndexConfiguration(["ownerId"])
                    try collection.createIndex(
                        withName: "idxTasksOwnerId", config: indexConfig)

                    //create cache queries used for LiveQuery
                    //
                    //`meta().id AS id` is selected explicitly so that the
                    //`@DocumentID` property on `Item` can be populated - the
                    //document ID lives in the document's metadata, not its body,
                    //so `SELECT *` would not return it.
                    //
                    //Naming the columns (rather than using `SELECT *`) also means
                    //each result row maps directly onto `Item`, with no wrapper
                    //object needed to unwrap a `SELECT *` alias.
                    let selectClause =
                        "SELECT meta().id AS id, summary, isComplete, ownerId "
                        + "FROM data.tasks "
                    self.queryAllTasks = try db.createQuery(selectClause)

                    var queryString = selectClause
                    queryString.append("WHERE ownerId = '\(user.username)' ")
                    queryString.append("ORDER BY META().id ASC")
                    self.queryMyTasks = try db.createQuery(queryString)

                    //setup replicator
                    guard let targetUrl = URL(string: app.appConfig.endpointUrl)
                    else {
                        app.error = InvalidEndpointUrl(
                            message: "URL in capellaConfig is invalid")
                        return
                    }
                    let targetEndpoint = URLEndpoint(url: targetUrl)

                    //configure the collection to sync
                    //
                    //In 4.0 the collection moved *into* `CollectionConfiguration`
                    //and `ReplicatorConfiguration.collections` became read-only,
                    //so collections are passed to the initializer instead of being
                    //added afterwards - `addCollection` was removed.
                    let collectionConfig = CollectionConfiguration(
                        collection: collection)

                    //create replicator config
                    var config = ReplicatorConfiguration(
                        collections: [collectionConfig], target: targetEndpoint)
                    config.replicatorType = .pushAndPull
                    config.continuous = true

                    //add authentication
                    let auth = BasicAuthenticator(
                        username: user.username, password: user.password)
                    config.authenticator = auth

                    //create the replicator
                    self._replicator = Replicator(config: config)

                    //observe replication status changes
                    self._replicator?.changePublisher()
                        .sink { (change) in
                            if let error = change.status.error {
                                print("replicator error state \(error)")
                            } else {
                                print("current state \(change.status.activity)")
                            }
                        }
                        .store(in: &cancellables)

                    if let replicator = self._replicator {
                        replicator.start()
                        app.setDatabaseState(.open)
                    }
                }
            }
        } catch {
            app.setDatabaseState(.error(error))
        }
    }

    /// Adds a task to the database with the specified summary.
    ///
    /// This function validates the currently logged-in user and adds a new task to the `taskCollection` if available.
    /// The task is created with the provided summary, and the current user's username is set as the owner.
    /// If the task cannot be serialized or if required resources (such as the user or the collection) are unavailable,
    /// appropriate error messages are set in the app's error state.
    ///
    /// - Parameter taskSummary: A `String` containing the summary of the task to be added.
    ///
    /// - Important: This function requires a valid logged-in user. If the user is not logged in, the function will
    ///   terminate early, and an `InvalidCredentialsException` will be set in the app's error state.
    ///
    /// - Throws: An error if there is an issue creating or saving the document in the database.
    ///
    /// - SeeAlso: `InvalidCredentialsException`, `InvalidStateError`
    func addTask(taskSummary: String) {
        do {
            //validate the user is logged in
            guard let currentuser = app.currentUser
            else {
                app.setError(InvalidCredentialsException(
                    message: "User is not logged in."))
                return
            }
            guard let collection = taskCollection
            else {
                app.setError(InvalidStateError(
                    message: "taskCollection is not available."))
                return
            }
            let task = Item(
                isComplete: false, summary: taskSummary,
                ownerId: currentuser.username)

            //`save(from:)` encodes the Codable object directly. `task.id` is nil
            //here, so Couchbase Lite generates a document ID and writes it back
            //to the `@DocumentID` property.
            try collection.save(from: task)

        } catch {
            app.setError(error)
        }
    }

    /// Closes the database and stops any active subscriptions and replicators.
    ///
    /// This function performs the following actions in sequence:
    /// 1. Cancels this service's Combine subscriptions, which stops observing replicator status.
    /// 2. Stops the replicator if it is currently running.
    /// 3. Closes the database connection safely.
    ///
    /// If an error occurs during any of these operations, it is caught and stored in the application's error state.
    ///
    /// - Throws: An error if the database fails to close properly.
    ///
    /// - Important: This function should be called when you no longer need access to the database or when the app is terminating
    ///   to ensure resources are released properly and replication is stopped.
    func close() {
        do {
            self.cancellables.removeAll()
            self._replicator?.stop()
            try self.database?.close()
        } catch {
            app.setError(error)
        }
    }

    /// Deletes a specified task from the database.
    ///
    /// This function attempts to locate and delete a task document from the `taskCollection` based on the provided item's ID.
    /// If the task collection or document is not available, it sets an appropriate error in the app's error state and
    /// exits early. Any other errors encountered during deletion are caught and handled.
    ///
    /// - Parameter item: An `Item` representing the task to be deleted. The function uses the `id` property of the `Item`
    ///   to locate the corresponding document in the database.
    ///
    /// - Important: Ensure that the `taskCollection` is properly initialized and accessible before calling this function.
    ///   If the `taskCollection` or the document does not exist, an `InvalidStateError` is set in the app's error state.
    ///
    /// - Throws: An error if there is an issue retrieving or deleting the document in the collection.
    ///
    /// - SeeAlso: `InvalidStateError`
    func deleteTask(item: Item) {
        do {
            guard let collection = taskCollection
            else {
                app.setError(InvalidStateError(
                    message: "taskCollection is not available."))
                return
            }
            guard let documentId = item.id
            else {
                app.setError(InvalidStateError(
                    message: "item has not been saved and has no document id"))
                return
            }
            //Read the stored document to verify ownership before deleting. The
            //Codable `delete(for:)` API never touches the stored document, so this
            //check has to be made explicitly.
            guard let doc = try collection.document(id: documentId)
            else {
                app.setError(InvalidStateError(message: "document not found"))
                return
            }
            let ownerId = doc.string(forKey: "ownerId")
            if ownerId != item.ownerId {
                throw InvalidStateError(
                    message: "document does not belong to current user")
            }
            try collection.delete(for: item)
        } catch {
            app.setError(error)
        }
    }

    /// Returns the cached live query for the given subscription type.
    ///
    /// The caller subscribes to the returned query with `changePublisher()` and owns
    /// the resulting subscription, so the view model - not this service - decides when
    /// observation starts and stops.
    ///
    /// - Parameter subscriptionType: Use `Constants.allItems` for every task, or
    ///   `Constants.myItems` for only the signed-in user's tasks.
    ///
    /// - Returns: The corresponding `Query`, or `nil` if the database has not been
    ///   initialized yet.
    ///
    /// - SeeAlso: `Constants.allItems`, `Constants.myItems`
    func tasksQuery(subscriptionType: String) -> Query? {
        subscriptionType == Constants.allItems ? queryAllTasks : queryMyTasks
    }

    /// Pauses the synchronization process by stopping the replicator.
    ///
    /// This function stops the active replicator, if available, effectively pausing any ongoing synchronization process
    /// with the database. It should be used when you want to temporarily halt sync operations without fully shutting down
    /// the database connection. To resume synchronization, the replicator must be restarted explicitly.
    ///
    /// - Important: Ensure that the replicator is properly configured and running before calling this function.
    ///   If the replicator is not active, this function has no effect.
    ///
    /// - SeeAlso: `resumeSync()`, `stopSync()`
    func pauseSync() {
        self._replicator?.stop()
    }

    /// Resumes the synchronization process by starting the replicator.
    ///
    /// This function starts the replicator, if available, to resume the synchronization process with the database.
    /// It should be used when you want to continue sync operations after they have been paused or stopped.
    /// Ensure that the replicator is properly configured before calling this function.
    ///
    /// - Important: If the replicator is already running, this function has no effect.
    ///   Make sure the replicator is in a paused or stopped state before calling this function to avoid unnecessary calls.
    ///
    /// - SeeAlso: `pauseSync()`
    func resumeSync() {
        self._replicator?.start()
    }

    /// Updates an existing task item in the database with the specified completion status and summary.
    ///
    /// This function performs several checks before updating the task item:
    /// 1. Verifies that the task collection is available.
    /// 2. Checks if the document with the specified item ID exists in the collection.
    /// 3. Ensures that the current user is the owner of the document.
    ///
    /// If any of these checks fail, the function sets an appropriate error on the `app` object.
    /// If all checks pass, the function updates the document's `isComplete` and `summary` fields in the database.
    ///
    /// - Parameters:
    ///   - item: The `Item` instance representing the task to be updated. It should contain the task's ID and owner information.
    ///   - isComplete: A `Bool` indicating whether the task is marked as complete.
    ///   - summary: A `String` containing the updated summary text for the task.
    ///
    /// - Throws: If an error occurs during document retrieval or saving, it is caught and passed to the `app.setError` function to handle the error.
    func updateItem(item: Item, isComplete: Bool, summary: String) {
        do {
            guard let collection = taskCollection
            else {
                app.setError(InvalidStateError(
                    message: "taskCollection is not available."))
                return
            }
            guard let documentId = item.id
            else {
                app.setError(InvalidStateError(
                    message: "item has not been saved and has no document id"))
                return
            }
            //Read the stored document to verify ownership before updating. The
            //Codable `save(from:)` API never touches the stored document, so this
            //check has to be made explicitly.
            guard let doc = try collection.document(id: documentId)
            else {
                app.setError(InvalidStateError(message: "document not found"))
                return
            }
            let ownerId = doc.string(forKey: "ownerId")
            if ownerId != item.ownerId {
                throw InvalidStateError(
                    message: "document does not belong to current user")
            }
            item.isComplete = isComplete
            item.summary = summary
            try collection.save(from: item)
        } catch {
            app.setError(error)
        }
    }
}
