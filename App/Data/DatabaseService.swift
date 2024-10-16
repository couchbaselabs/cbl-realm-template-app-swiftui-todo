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
    fileprivate var _replicatorStatusToken: ListenerToken? = nil
    fileprivate var _replicator: Replicator? = nil

    //database information
    var database: Database? = nil
    var taskCollection: Collection? = nil

    //cached queries
    var queryMyTasks: Query? = nil
    var queryAllTasks: Query? = nil

    //used for query listener (live query)
    var queryListenerToken: ListenerToken? = nil
    var taskLiveQueryObserver: (([Item]?) async -> Void)?

    init() {
        Database.log.console.level = .debug
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
                    var queryString = "SELECT * FROM data.tasks as item "
                    self.queryAllTasks = try db.createQuery(queryString)

                    queryString.append(
                        "WHERE item.ownerId = '\(user.username)' ")
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

                    //create replicator config
                    var config = ReplicatorConfiguration(target: targetEndpoint)
                    config.replicatorType = .pushAndPull
                    config.continuous = true

                    //configure collections to sync
                    let collectionConfig = CollectionConfiguration()
                    config.addCollection(collection, config: collectionConfig)

                    //add authentication
                    let auth = BasicAuthenticator(
                        username: user.username, password: user.password)
                    config.authenticator = auth

                    //create the replicator
                    self._replicator = Replicator(config: config)

                    //handle listeners for replication status to calculate
                    //status change
                    self._replicatorStatusToken = self._replicator?
                        .addChangeListener({ (change) in
                            if let error = change.status.error {
                                print("replicator error state \(error)")
                            } else {
                                print("current state \(change.status.activity)")
                            }
                        })

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
            if let json = task.toJSON() {
                let mutableDocument = try MutableDocument(
                    id: task.id, json: json)
                try collection.save(document: mutableDocument)
            } else {
                app.setError(InvalidStateError(
                    message: "item could not be serialized"))
            }

        } catch {
            app.setError(error)
        }
    }

    /// Closes the database and stops any active listeners and replicators.
    ///
    /// This function performs the following actions in sequence:
    /// 1. Removes the query listener token, if it exists, to stop observing query changes.
    /// 2. Removes the replicator status token, if it exists, to stop monitoring replicator status updates.
    /// 3. Stops the replicator if it is currently running.
    /// 4. Closes the database connection safely.
    ///
    /// If an error occurs during any of these operations, it is caught and stored in the application's error state.
    ///
    /// - Throws: An error if the database fails to close properly.
    ///
    /// - Important: This function should be called when you no longer need access to the database or when the app is terminating
    ///   to ensure resources are released properly and replication is stopped.
    func close() {
        do {
            self.queryListenerToken?.remove()
            self._replicatorStatusToken?.remove()
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
            guard let doc = try collection.document(id: item.id)
            else {
                app.setError(InvalidStateError(message: "document not found"))
                return
            }
            let ownerId = doc.string(forKey: "ownerId")
            if ownerId != item.ownerId {
                throw InvalidStateError(
                    message: "document does not belong to current user")
            }
            try collection.delete(document: doc)
        } catch {
            app.setError(error)
        }
    }

    /// Sets up a live query observer to monitor changes in the task list based on the specified subscription type.
    ///
    /// This function sets an observer that listens for changes in the task list using a live query. Depending on the
    /// provided subscription type, it runs either the query for all tasks or the query for the current user's tasks.
    /// When the query detects changes, the observer is called with the updated list of tasks. If an observer is already
    /// set, it removes the existing listener before setting up a new one.
    ///
    /// - Parameters:
    ///   - subscriptionType: A `String` representing the type of subscription for the task list.
    ///     Use `Constants.allItems` to observe all tasks or `Constants.myItems` for observing the current user's tasks.
    ///   - observer: An optional closure `(([Item]?) -> Void)?` that is called with the updated list of tasks when
    ///     changes are detected by the live query. If `nil`, the function will remove any existing query listener.
    ///
    /// - Important: Ensure that the subscription type matches the constants used to differentiate between all tasks
    ///   and user-specific tasks. If the subscription type is not recognized, the function may not set up the appropriate query.
    ///
    /// - Note: If an observer is already active when this function is called, the existing query listener token will be
    ///   removed before adding the new listener.
    ///
    /// - SeeAlso: `Constants.allItems`, `Constants.myItems`
    func setTasksListChangeObserver(
        subscriptionType: String, observer: (([Item]?) async -> Void)?
    ) {
        taskLiveQueryObserver = observer
        var query: Query? = nil

        if taskLiveQueryObserver != nil {
            //if existing query listener is running, remove it
            if let token = queryListenerToken {
                token.remove()
            }

            //figure out which query to run
            if subscriptionType == Constants.allItems {
                query = queryAllTasks
            } else {
                query = queryMyTasks
            }
            if let runQuery = query {
                queryListenerToken =
                    runQuery
                    .addChangeListener({[weak self] (change) in
                        var items: [Item] = []
                        if let results = change.results {
                            for result in results {
                                let json = result.toJSON()
                                if let itemDao = ItemDao(json: json) {
                                    items.append(itemDao.item)
                                } else {
                                    print("error deserializing item from query")
                                }
                            }
                            Task {
                                await self?.taskLiveQueryObserver?(items)
                            }
                        }
                    })
            }
        }
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
            guard let doc = try collection.document(id: item.id)
            else {
                app.setError(InvalidStateError(message: "document not found"))
                return
            }
            let ownerId = doc.string(forKey: "ownerId")
            if ownerId != item.ownerId {
                throw InvalidStateError(
                    message: "document does not belong to current user")
            }
            let mutableDoc = doc.toMutable()
            mutableDoc.setBoolean(isComplete, forKey: "isComplete")
            mutableDoc.setString(summary, forKey: "summary")
            try collection.save(document: mutableDoc)
        } catch {
            app.setError(error)
        }
    }
}
