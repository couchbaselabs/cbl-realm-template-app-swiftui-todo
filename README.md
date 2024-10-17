# Conversion Example of MongoDb Atlas Device Sync to Couchbase Lite for SwiftUI Developers
The original version of this [application](https://github.com/mongodb/template-app-swiftui-todo)  was built with the [MongoDb Atlas Device SDK for SwiftUI](https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/swiftui/) and [Atlas Device Sync](https://www.mongodb.com/docs/atlas/app-services/sync/).  

This repository provides a converted version of the application using [Couchbase Lite for Swift SDK](https://docs.couchbase.com/couchbase-lite/current/swift/gs-prereqs.html) along with [Capella App Services](https://docs.couchbase.com/cloud/app-services/index.html).  

> [!NOTE]
>The original application is a basic To-Do list, and its source code follows a specific approach for implementing a SwiftUI application and managing communication between layers. While the Realm SDK offers a library tailored for SwiftUI, Couchbase Lite provides a Swift SDK. In the original code, many of the Realm interactions were handled directly within the `View`. In this conversion, we’ve moved business logic and state management to a `ViewModel`pattern for a clearer separation of concerns.
>
>This conversion is by no means a best practice for SwiftUI development or a showcase on how to properly communicate between layers of an application.  It's more of an example of some of the process that a developer would have to go through to convert an application from one SDK to another.
>

Some UI changes were made to remove wording about Realm and replaced with Couchbase.

# Requirements
- Xcode 16.0 or later
- Basic [SwiftUI](https://developer.apple.com/xcode/swiftui/) knowledge
- Basic [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/) knowledge
- Understanding of the [Realm SDK for SwiftUI](https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/swiftui/)

# Fetching the App Source Code

Clone this repository from GitHub using the command line or your Git client:

```bash
git clone https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo.git
```

## Capella Configuration
Before running this application, make sure you have [Couchbase Capella App Services](https://docs.couchbase.com/cloud/get-started/configuring-app-services.html) set up.  
You can find detailed instructions for setting up Couchbase Capella App Services and updating the configuration file in the [Capella.md](./Capella.md) file located in this repository. Be sure to complete these steps before proceeding.

# App Overview
The following diagram shows the flow of the application

![App Flow](Swift-Todo-App-Overview.png)

# SwiftUI App Conversion 
Several files were changed or added in the conversion process. 

## Package Dependencies 
The app Package Dependencies were updated, removing the Realm and Realm Database frameworks.  The CouchbaseLiteSwift framework was added to the project.  The [Couchbase Lite documentation](https://docs.couchbase.com/couchbase-lite/current/swift/gs-install.html#lbl-install-tabs) covers the various methods for adding the CouchbaseLiteSwift library to a new or existing project.  In this project we used Swift Package Manager (SPM).

> [!WARNING]
> Some XCode users have reported issues restoring the SPM dependencies.  If you have issues, you might need to reset your package cache.  When searching the internet on this problem, most “solutions” on the forums revolve around some magical combination:
> - Cleaning your project (cmd-shift-K)
> - Deleting Xcode’s DerivedData/,
> - Running File > Packages > Reset Package Caches
> - Running File > Packages > Resolve Package Versions
> - Closing and re-opening Xcode.
>

## App Services Configuration File
The original source code had the configuration for Atlas App Services stored in the atlasConfig.plist file located in the App folder.  This file was removed and the configuration for Capella App Services was added in the [capellaConfig.plist]() file. 

You will need to modify this file to add your Couchbase Capella App Services endpoint URL, as outlined in the [Capella setup instructions](./Capella.md).

##  realmSwiftUIApp changes and CBLiteApp
The original source code had the SwiftUI.App [Application](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/App.swift#L4) inheriting from a custom realmSwiftUIApp that creates a local RMLApp instance app.

The first major change was to the main app, which was to switch out the global app variable to a new classed called [CBLApp](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Data/CBLApp.swift#L3). 

```swift
let appConfig = loadAppConfig()
let app = CBLApp(configuration: appConfig)

@main
struct todoSwiftUIApp: SwiftUI.App {
  ...
}
```

The local app variable is used to reference features in the Realm SDK, such as authentication and the currently authenticated user. Since this is defined within the Application class, it effectively becomes a global variable for the entire app. This approach requires developers to update most of the code that references the app variable.  To limit the amount of code required to change, the current authenticated user is tracked in CBLApp. 


## Authentication 
The [Couchbase Lite SDK](https://docs.couchbase.com/couchbase-lite/current/android/replication.html#lbl-user-auth)  manages authentication differently than the [Mongo Realm SDK](https://www.mongodb.com/docs/atlas/device-sdks/sdk/kotlin/users/authenticate-users/#std-label-kotlin-authenticate).  Code was added to deal with these differences.   

### Handling Authentication of the App

The authentication of the app is called from a new [AuthenticationService](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Data/AuthenticationService.swift#L13) that was added to the app.

The AuthenticationService handles authentication via the Couchbase Capella App Services Endpoint public [REST API](https://docs.couchbase.com/cloud/app-services/references/rest_api_admin.html) in its login function.  A new LoginViewModel [login function](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/ViewModels/LoginViewModel.swift#L19) was added to the application, calling the AuthenticationService and validating that the username and password provided can authenticate with the endpoint (or throwing an exception if they can't).

> [!NOTE]
>Registering new users is out of scope of the conversion, so this functionaliy was removed.  Capella App Services allows the creating of Users per endpoint via the [UI](https://docs.couchbase.com/cloud/app-services/user-management/create-user.html#usermanagement/create-app-role.adoc) or the [REST API](https://docs.couchbase.com/cloud/app-services/references/rest_api_admin.html).  For large scale applications, it's highly recommended to use a 3rd party [OpendID Connect](https://docs.couchbase.com/cloud/app-services/user-management/set-up-authentication-provider.html) provider. 
>

### Authentication Exceptions

Two new exceptions were created to mimic the Realm SDK exceptions for authentication: 
- [ConnectionException](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Data/CBLApp.swift#L14) is thrown if the app can't reach the Capella App Services REST API
- [InvalidCredentialsException](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Data/CBLApp.swift#L18) is thrown if the username or password is incorrect 

### Create User Model

The Couchbase Lite SDK doesn't provide a user object for tracking the authenticated user, so a [new model](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Models/User.swift) was created. 

## Updating Item Domain Model

The [Item](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Models/Item.swift#L22) file was modified to remove the Realm annotations and to refactor some properties to meet standard Swift conventions for serialization.

The Item class was changed to support the Codable and Identifiable protocols. The Swift serialization library allows the conversion of the class to a JSON string for storage in Couchbase Lite, so changes were made to the class to make it serializable by the Swift serialization library.

Finally, a [ItemDAO](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Models/Item.swift#L3) (Data Access Object) was created to help with the deserialization of the Query Results that come back from a SQL++ QueryChange object.

## Database Service 

A new [DatabaseService](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Data/DatabaseService.swift) was created to handle interactions between the Couchbase Lite Database, Collection, and Replicator and the rest of the application.  

### Initialize Couchbase Lite Database and Replication Configuration

The DatabaseService [ininitializeDatabase](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Data/DatabaseService.swift#L78) function handles the following tasks:

- Initalization of the Database
- Creation of the Collection
- Creation of Indexes
- Creation of Cached Queries
- Setup of the Replicator.  

The following code snippet creates the database file and the `data.tasks` collection.

```swift
 self.database = try Database(name: databaseName)
  if let db = self.database  {
   
  self.taskCollection = try db
    .createCollection(
      name: _taskCollectionName, 
      scope:_scopeName)
  ...
}
```

#### Index Setup 
An index is created to help speed up the query where tasks are filtered out by the ownerId field.  This is done by calling the createIndex method on the collection object.

```swift
//create index
let indexConfig = ValueIndexConfiguration(["ownerId"])
try collection.createIndex(
  withName:"idxTasksOwnerId", 
  config: indexConfig)
```

#### Cached Query Setup 
Next, two basic queries for the application are created:  One to get the current users tasks and one to get all tasks. Queries are compiled when created from the `db.createQuery` function.  By initializing the query when the service is intialized, we can use the query later in the application without having to recompile the query each time the setTasksListChangeObserver function is run. 

```swift
 //create cache queries used for LiveQuery
var queryString = "SELECT * FROM data.tasks as item "
self.queryAllTasks = try db.createQuery(queryString)
                    
queryString.append("WHERE item.ownerId = '\(user.username)' ")
queryString.append("ORDER BY META().id ASC")
self.queryMyTasks = try db.createQuery(queryString)
```

Caching queries aren't required, but can save on resources if the same query is run multiple times. 

#### Replicator Setup 
Next the [Replication Configuration](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Data/DatabaseService.swift#L118) is created using the Endpoint URL that is provided from the resource file described earlier in this document.  The configuration is setup in a [PULL_AND_PUSH](https://docs.couchbase.com/couchbase-lite/current/swift/replication.html#lbl-cfg-sync) configuration which means it will pull changes from the remote database and push changes to Capella App Services. By setting continuous to true the replicator will continue to listen for changes and replicate them.  

```swift
var config = ReplicatorConfiguration(target: targetEndpoint)
config.replicatorType = .pushAndPull
config.continuous = true
```

> [!TIP]
>The Couchbase Lite SDK [Replication Configuration](https://docs.couchbase.com/couchbase-lite/current/swift/replication.html#lbl-cfg-repl) API also supports [filtering of channels](https://docs.couchbase.com/couchbase-lite/current/swift/replication.html#lbl-repl-chan) to limit the data that is replicated to the device. 
>

Authentication to App Services is added to  sync information based on the current authenticated user.

```swift
let auth = BasicAuthenticator(
  username: user.username, 
  password: user.password)
config.authenticator = auth
```
#### Replicator Status 
A change listener for [Replication Status](https://docs.couchbase.com/couchbase-lite/current/swift/replication.html#lbl-repl-status) is created and is used to track any errors that might happen. 

```swift
//handle listeners for replication status to calculate
//status change
self._replicatorStatusToken = self._replicator?.addChangeListener 
  ({ (change) in
  DispatchQueue.main.async {
   if let error = change.status.error {
     print("replicator error state \(error)")
   } else {
     print ("current state \(change.status.activity)" )
   }
  }
})
```
> [!IMPORTANT]
>Swift Developers should review the [Couchbase Lite SDK documentation for Swift](https://docs.couchbase.com/couchbase-lite/current/swift/replication.html#introduction) prior to making decisions on how to setup the replicator.
>

### addTask function 

The [addTask function](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Data/DatabaseService.swift#L176) was created to add a task to the CouchbaseLite Database using JSON serialization.  The method is shown below:

```swift
guard let collection = taskCollection
 else {
  app.error = InvalidStateError(
    message: "taskCollection is not available.")
  return
}
let task = Item(
  isComplete: false, 
  summary: taskSummary, 
  ownerId: currentuser.username)
if let json = task.toJSON() {
  let mutableDocument = try MutableDocument(id: task.id, json: json)
  try collection.save(document: mutableDocument)
} else {
  app.error = InvalidStateError(
    message: "item could not be serialized")
}
```
The task is serialized into a JSON string using the Swift serialization library and then saved to the collection via the [MutableDocument](https://docs.couchbase.com/couchbase-lite/current/swift/document.html#create-a-document) object.  If an error occurs, the app.error handler is set with the exception that was thrown.

### close method

The close method is used to remove any query listeners, the replication status change listener, stop replication, and then close the database.  This will be called when the user logs out from the application making sure if the application is used by multiple uses to close out all resources before another user logs into the application.

```swift
func close() {
 do {
  self.queryListenerToken?.remove()
  self._replicatorStatusToken?.remove()
  self._replicator?.stop()
  try self.database?.close()
 } catch {
  app.error = error
 }
}
```

### Handling Security of Updates/Delete

In the original app, Realm was handling the security of updates to validate that the current logged in user can update its own tasks, but not other users's task.  When the switch in the application is used to see All Tasks using different subscription, they would have read-only access to the objects.  

Couchbase Lite doesn't have the same security model.  In this application the following approach was taken.  

The code of the application was modified to validate that write access is only allowed by users that own the tasks and the Data Access and Validation script was added in the Capella setup instructions that limits whom can write updates.

> [!TIP]
> Develoeprs can use a Custom [Replication Conflict Resolution](https://docs.couchbase.com/couchbase-lite/current/android/conflict.html#custom-conflict-resolution) to receive the result in your applications code and then revert the change.
>

### deleteTask method

The deleteTask method removes a task from the database.  This is done by retrieving the document from the database using the `collection.document` function and then calling the collection `delete` function.  A security check was added so that only the owner of the task can delete the task.

```swift
func deleteTask(item: Item){
  do {
    guard let collection = taskCollection
    else {
      app.error = InvalidStateError(message: "taskCollection is not available.")
      return
    }
    guard let doc = try collection.document(id: item.id)
    else {
      app.error = InvalidStateError(message: "document not found")
      return
    }
    let ownerId = doc.string(forKey: "ownerId")
    if (ownerId != item.ownerId){
       throw InvalidStateError(message: "document does not belong 
       to current user")
    }
    try collection.delete(document: doc)
    } catch {
      app.error = error
   }
}
```
### setTasksListChangeObserver function 

Couchbase Lite doesn't support the various patterns that Realm provides for tracking changes in a Realm.  Instead Couchbase Lite has the [LiveQuery](https://docs.couchbase.com/couchbase-lite/current/swift/query-live.html#activating-a-live-query) API.  A live query is a query that, once activated, remains active and monitors the database for changes; refreshing the result set whenever a change occurs.  Unlike Realm, when a change is detected, the entire query is re-run and the results are updated.   

Couchbase Lite has a different way of handing replication and security than the Atlas Device SDK [Subscription API](https://www.mongodb.com/docs/atlas/device-sdks/sdk/kotlin/sync/subscribe/#subscriptions-overview).  Because of this, two queries were created to pull the information from the database based on the users selection.  One query is for all tasks and the other is for the current users tasks.  The setTasksListChangeObserver function is used to setup the LiveQuery and then call the completion handler with the results of the query so that the ViewModel can update the observed array of items. 

```swift 
  func setTasksListChangeObserver(subscriptionType: String, observer: (([Item]?) -> Void)?) {

taskLiveQueryObserver = observer
var query:Query? = nil
        
if (taskLiveQueryObserver != nil) {
 //if existing query listener is running, remove it
 if let token =  queryListenerToken {
  token.remove()
 }
 //figure out which query to run
 if (subscriptionType == Constants.allItems){
  query = queryAllTasks
 } else {
  query = queryMyTasks
 }
 if let runQuery = query {
  queryListenerToken = runQuery
  .addChangeListener({ [self] ( change ) in
   var items: [Item] = []
   if let results = change.results {
     for result in results {
      let json = result.toJSON()
      if let itemDao = ItemDao(json: json){
       items.append(itemDao.item)
      } else {
       print("error deserializing item from query")
      }
    }
    taskLiveQueryObserver?(items)
    }
   })
  }
 } 
}
```

> [!IMPORTANT]
>Developers should review the Couchbase Capella App Services [channels](https://docs.couchbase.com/cloud/app-services/channels/channels.html) and [roles](https://docs.couchbase.com/cloud/app-services/user-management/create-app-role.html) documentation to understand the security model it provides prior to planning an application migration. 
>

### updateItem function 
The updateItem function is used to update a task. This is done by retrieving the document from the database using the collection.getDocument method and then updating the document with the new value for the isComplete and summary property. A security check was added so that only the owner of the task can update the task.  The document is then saved back to the collection.

Swift serialization could have been used to perform this update, but is inefficient as only two properties are updated and seralization of the entire object would cost more resources.  

```swift
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
```
## Other Application Changes

### Rename OpenRealmView 
The [OpenRealmView](https://github.com/mongodb/template-app-swiftui-todo/blob/main/App/Views/OpenRealmView.swift) from the original repo was renamed to [OpenDatabaseView](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Views/OpenDatabaseView.swift#L4).

### Moving UI Components to Components folder
The following UI components were moved to the Components folder inside of the View folder for better organization of the code:
- ItemDetail
- ItemList
- ItemRow
- LogoutButton

### New ViewModels
Several new ViewModels were added to the application to interact between the View and Database Service.  In most cases, state management was moved from the View to the ViewModel.

- [CreateItemViewModel](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/ViewModels/CreateItemViewModel.swift) - handles the creation of a new task from the [CreateItemView](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Views/CreateItemView.swift).
- [ItemDetailViewModel](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/ViewModels/ItemDetailViewModel.swift) - handles updating a task from the [ItemDetail](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Views/Components/ItemDetail.swift) component.
- [ItemsViewModel](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/ViewModels/ItemsViewModel.swift) - handles calling live query for getting the array of task for the [ItemsView](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Views/ItemsView.swift) to render.  It also handles deleting of tasks.
- [LoginViewModel](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/ViewModels/LoginViewModel.swift) - handles authenticating of the user from the [LoginView](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Views/LoginView.swift) and calling the initalization of the database.
- [LogoutViewModel](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/ViewModels/LogoutViewModel.swift) - handles logging the user out of the application including closing all database resources from the [LogoutButton](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Views/Components/LogoutButton.swift).  
- [OpenDatabaseViewModel](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/ViewModels/OpenDatabaseViewModel.swift) - used for stopping and starting replication to simulate the user going offline and online which is done via a button in the [OpenDatabaseView](https://github.com/couchbaselabs/cbl-realm-template-app-swiftui-todo/blob/main/App/Views/OpenDatabaseView.swift#L50). 

### Updated ItemDetail view
The ItemDetail view was updated to add a button for saving the task updates that are performed on the view.  The new button calls the ItemDetailViewModel to update the task in the database.

More Information
----------------
- [Couchbase Lite for Swift documentation](https://docs.couchbase.com/couchbase-lite/current/swift/quickstart.html)
- [Couchbase Capella App Services documentation](https://docs.couchbase.com/cloud/app-services/index.html)



Disclaimer
----------
The information provided in this documentation is for general informational purposes only and is provided on an “as-is” basis without any warranties, express or implied. This includes, but is not limited to, warranties of accuracy, completeness, merchantability, or fitness for a particular purpose. The use of this information is at your own risk, and the authors, contributors, or affiliated parties assume no responsibility for any errors or omissions in the content.

No technical support, maintenance, or other services are offered in connection with the use of this information. In no event shall the authors, contributors, or affiliated parties be held liable for any damages, losses, or other liabilities arising out of or in connection with the use or inability to use the information provided.
