# Conversion Example of MongoDb Atlas Device Sync to Couchbase Lite for SwiftUI Developers 

The original version of this [application](https://github.com/mongodb/template-app-swiftui-todo)  was built with the [MongoDb Atlas Device SDK for SwiftUI](https://www.mongodb.com/docs/atlas/device-sdks/sdk/swift/swiftui/) and [Atlas Device Sync](https://www.mongodb.com/docs/atlas/app-services/sync/).  

This repository provides a converted version of the application using Couchbase Mobile ([Couchbase Lite for Swift SDK](https://docs.couchbase.com/couchbase-lite/current/swift/gs-prereqs.html) along with [Capella App Services](https://docs.couchbase.com/cloud/app-services/index.html).  

> **NOTE**
>The original application is a basic To Do list.  The original source code has it's own opinionated way of implementing an SwiftUI application and communicating between different layers.  This conversion is by no means a best practice for SwiftUI development or a show case on how to properly communicate between layers of an application.  It's more of an example of the process that a developer will have to go through to convert an application from one SDK to another.
>

Some minior UI changes were made to remove wording about Realm and replaced with Couchbase.

# Capella Configuration

Before running this application, you must have [Couchbase Capella App Services](https://docs.couchbase.com/cloud/get-started/configuring-app-services.html) set up.  Instructions for setting up Couchbase Capella App Services and updating the configuration file can be found in the [Capella.md](./Capella.md) file in this repository.  Please ensure you complete these steps first.

# SwiftUI App Conversion 

The following is information on the application conversion process and what files were changed.

## Package Dependencies 
The app Package Dependicies were updated, removing the Realm and Realm Database frameworks.  The CouchbaseLiteSwift framework was added to the project.  The [Couchbase Lite documentation](https://docs.couchbase.com/couchbase-lite/current/swift/gs-install.html#lbl-install-tabs) covers the various methods for adding the CouchbaseLiteSwift library to a new or existing project.


## App Services Configuration File

The original source code had the configuration for Atlas App Services stored in the atlasConfig.plist file located in the App folder.  This file was removed and the configuration for Capella App Services was added in the [capellaConfig.plist]() file. 

You will need to modify this file to add your Couchbase Capella App Services endpoint URL, as outlined in the [Capella setup instructions](./Capella.md).

##  realmSwiftUIApp changes and CBLiteApp


The original source code had the SwiftUI.App [Application]() inheriting from a custom realmSwiftUIApp that creates a local RMLApp instance app.

The first major change was to the main app, which was renamed to todoSwiftUIApp.

```swift
struct todoSwiftUIApp: SwiftUI.App {
  ....
}
```

The local app variable is used to reference features in the Realm SDK, such as authentication and the currently authenticated user. Since this is defined within the Application class, it effectively becomes a global variable for the entire app. This approach requires developers to update most of the code that references the app variable. While other patterns, like Dependency Injection, could be used to provide these references, for the purposes of this conversion, we have maintained the same pattern.  

A new class [CBLApp]() was created to mimic some of the behaviors of the RLMApp class.  


## Authentication 

The [Couchbase Lite SDK](https://docs.couchbase.com/couchbase-lite/current/android/replication.html#lbl-user-auth)  manages authentication differently than the [Mongo Realm SDK](https://www.mongodb.com/docs/atlas/device-sdks/sdk/kotlin/users/authenticate-users/#std-label-kotlin-authenticate).  Code was added to deal with these differences.   

### Handling Authencation of the App

The authentication of the app is called from the [AuthRepository](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/data/AuthRepository.kt#L9) interface.  The implementation [AppEndpointAuthRepository](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/data/AuthRepository.kt#L19) was renamed to [AppServicesAuthRepository](AppServicesAuthRepository). 

Authentication is done via the Couchbase Capella App Services Endpoint public [REST API](https://docs.couchbase.com/cloud/app-services/references/rest_api_admin.html) in the CBLiteApp [login function](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/CBLiteApp.kt#L15), validating that the username and password provided can authenticate with the endpoint (or throwing an exception if they can't).

The login method was added to the [CBLiteApp](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/CBLiteApp.kt#L15) to resolve the SDK differences between Realm SDK and Couchbase Lite SDK without having to refactor large chunks of code. 

> [!NOTE]
>Registering new users is out of scope of the conversion, so this functionaliy was removed.  Capella App Services allows the creating of Users per endpoint via the [UI](https://docs.couchbase.com/cloud/app-services/user-management/create-user.html#usermanagement/create-app-role.adoc) or the [REST API](https://docs.couchbase.com/cloud/app-services/references/rest_api_admin.html).  For large scale applications it's highly recommended to use a 3rd party [OpendID Connect](https://docs.couchbase.com/cloud/app-services/user-management/set-up-authentication-provider.html) provider. 
>

### Authentication Exceptions

Two new exceptions were created to mimic the Realm SDK exceptions for authentication: 
- [ConnectionException](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/data/AuthExceptions.kt#L4C7-L4C26) is thrown if the app can't reach the Capella App Services REST API
- [InvalidCredentialsException](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/data/AuthExceptions.kt#L3C7-L3C34) is thrown if the username or password is incorrect 

### Create User Model

The Couchbase Lite SDK doesn't provide a user object for tracking the authenticated user, so a [new model](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/domain/User.kt) was created. 

## Updating Item Domain Model

The [Item.kt](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/domain/Item.kt) file was modified to remove the Realm annotations and to refactor some properties to meet standard Android conventions.

Couchbase Lite supports the use of Kotlin data classes for domain models, so the Item class was converted to a data class. The Kotlin serialization library makes it easy to convert the data class to a JSON string for storage in Couchbase Lite, so changes were made to the data class to make it serializable by the Kotlin serialization library.

Finally, a DAO (Data Access Object) was created to help with the deserialization of the Query Results that come back from a SQL++ QueryChange object without needing to further change the ViewModels.

## Updating Sync Repository

A heavy amount of the conversion code was done in the [SyncRepository](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/data/SyncRepository.kt#L26) file.  

### Implementation of SyncRepository Interface

The implementation of SyncRepository was renamed to [CouchbaseSyncRepository](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/data/SyncRepository.kt).  


### Initialize Couchbase Lite Database and Replication Configuration

The [CouchbaseSyncRepository init method](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/data/SyncRepository.kt#L104) implements the initalization of the Database and the creation of the data.items collection.  

```kotlin
 val dbConfig =
  DatabaseConfigurationFactory.newConfig(app.filesDir)
app.currentUser?.let { currentUser ->
  val username = currentUser.username
   .replace("@", "-")
   .lowercase(Locale.getDefault())
  this.database = Database("items${username}", dbConfig)
  this.collection = this.database.createCollection("items", "data")
```

#### Index Setup 
An index is created to help speed up the query where tasks are filtered out by the ownerId field.  This is done by calling the createIndex method on the collection object.

```kotlin
 //create index - check to see if it's created, if not create it
val indexOwnerId = this.collection.getIndex("idxTasksOwnerId")
if (indexOwnerId == null) {
  val idxOwnerId = IndexBuilder.valueIndex(ValueIndexItem.property("ownerId"))
  this.collection.createIndex("idxTasksOwnerId", idxOwnerId)
}
```
#### Replicator Setup 
Next the [Replication Configuration](https://docs.couchbase.com/couchbase-lite/current/android/replication.html#lbl-cfg-repl) is created using the Endpoint URL that is provided from the resource file described earlier in this document.  The configuration is setup in a [PULL_AND_PUSH](https://docs.couchbase.com/couchbase-lite/current/android/replication.html#lbl-cfg-sync) configuration which means it will pull changes from the remote database and push changes to Capella App Services. By setting continuous to true the replicator will continue to listen for changes and replicate them.  

```kotlin
val replicatorConfig = ReplicatorConfigurationFactory.newConfig(
   target = URLEndpoint(URI(app.endpointUrl)),
   type = ReplicatorType.PUSH_AND_PULL,
   continuous = true
)
replicatorConfig.collections.add(this.collection)
```

Authentication is added to only sync information based on the current authenticated user.

```kotlin
val auth =
  BasicAuthenticator(currentUser.username, currentUser.password.toCharArray())
replicatorConfig.authenticator = auth
```

#### Replicator Status 
A change listener for [Replication Status](https://docs.couchbase.com/couchbase-lite/current/android/replication.html#lbl-repl-status) is created and is used to track any errors that might happen from replication, which is then logged via the passed in onError closure.

```kotlin
this.statusChangeToken = this.replicator.addChangeListener { change ->
  val error: CouchbaseLiteException? = change.status.error
    error?.let { e ->
      onError(e)
    }
}
```

> [!NOTE]
>Android Developers should review the documentation on Ordering of replication events in the [Couchbase Lite SDK documentation for Kotlin](https://docs.couchbase.com/couchbase-lite/current/android/replication.html#lbl-repl-ord) prior to making decisions on how to setup the replicator in environments with heavy replication traffic.
>

#### Cached Query Setup 
Finally we setup our two basic queries for the application.  One to get the current users tasks and one to get all tasks. Queries are compiled when created from the `database.createQuery` method.  By initializing the query when the repository is intialized, we can use the query later in the application without having to recompile the query each time the getTasksList method is run. 

```kotlin
var queryString = "SELECT * FROM data.tasks as item "
this.queryAllTasks = this.database.createQuery(queryString)

queryString += "WHERE item.ownerId = '${currentUser.username}' "
queryString += "ORDER BY META().id ASC"
this.queryMyTasks = this.database.createQuery(queryString)
```

Caching queries aren't required, but can save memory and CPU time if the same query is run multiple times.  

### addTask method

The addTask method was  implemented to add a task to the CouchbaseLite Database using JSON serialization.  The method is shown below:

```kotlin
app.currentUser?.let { user ->
  val task = Item(
    ownerId = user.username,
    summary = taskSummary
  )
  withContext(Dispatchers.IO){
    try {
      val json = task.toJson()
      val mutableDoc = MutableDocument(task.id, json)
      collection.save(mutableDoc)
    } catch(e:Exception) {
      onError(e)
    }
  }
}
```

Note that database operations are executed on Dispatchers.IO to avoid blocking the main thread. The task is serialized into a JSON string using the Kotlin serialization library and then saved to the collection via the [MutableDocument](https://docs.couchbase.com/couchbase-lite/current/android/document.html#constructing-a-document) object.  If an error occurs, the onError callback is triggered with the exception that was thrown.

### close method

The close method is used to remove the Replication Status change listener, stop replication, and then close the database.  This will be called when the user logs out from the application.

```kotlin
override fun close(){
  this.statusChangeToken.close()
  this.replicator.stop()
  this.database.close()
}
```

### Handling Security of Updates/Delete

In the original app, Realm was handling the security of updates to validate that the current logged in user can update its own tasks, but not other users's task.  When the switch in the application is used to see All Tasks using different subscription, they would have read-only access to the objects.  

Couchbase Lite doesn't have the same security model.  Here are two ways to handle this in conversion:

1. Write custom logic in your application to validate that write access is only allowed by users that own the tasks.  This is independant of how the data is syncronized.

2. Allow the write to the database even though the user doesn't have access, and then let the replicator sync the changes.  In the App Services [Access Control and Data Validation](https://docs.couchbase.com/cloud/app-services/deployment/access-control-data-validation.html) [sync function](https://docs.couchbase.com/cloud/app-services/deployment/access-control-data-validation.html), check the security there and then deny the write.  Use a Custom [Replication Conflict Resolution](https://docs.couchbase.com/couchbase-lite/current/android/conflict.html#custom-conflict-resolution) to receive the result in your applications code and then revert the change.

If your app is offline for long periods of time, option 2 might not fit your security requirements. Because this app offers an offline mode, option 1 was selected for the security model in the conversion.

To further harden the security, the App Service sync script could check the ownerId field and use the [requireUser](https://docs.couchbase.com/cloud/app-services/deployment/access-control-data-validation.html#handling-modification) function to deny writes from other users.  This would secure the data from bugs in the application and double validate that writes are only performed by the owner of the task.

### deleteTask method

The deleteTask method removes a task from the database.  This is done by retrieving the document from the database using the collection.getDocument method and then calling the collection delete method.  A security check was added so that only the owner of the task can delete the task.

```kotlin
override suspend fun deleteTask(task: Item) {
  withContext(Dispatchers.IO) {
   try {
     val doc = collection.getDocument(task.id)
     doc?.let {
      //handle security of the owner only being able to delete their own tasks
      val ownerId = doc.getString("ownerId")
      if (ownerId != task.ownerId) {
       onError(IllegalStateException("User does not have permission to delete this task"))
      } else {
       collection.delete(it)
      }
     }
   } catch (e: Exception) {
     onError(e)
   }
  }
}
```


### getTaskList method

Couchbase Lite doesn't support the [ResultsChange](https://www.mongodb.com/docs/realm-sdks/kotlin/1.0.1/library-base/-realm%20-kotlin%20-s-d-k/io.realm.kotlin.notifications/-results-change/index.html) pattern that Realm provides for tracking changes in a Realm.  Instead Couchbase Lite has an API called [LiveQuery](https://docs.couchbase.com/couchbase-lite/current/android/query-live.html#activating-a-live-query)

If any information in the query results has changed, the query is run again and the results presented.  Couchbase Lite for Android with Kotlin specifically supports the Flow Co-Routine API for handling the [LiveQuery](https://docs.couchbase.com/couchbase-lite/current/android/query-live.html#activating-a-live-query) results which will return a [QueryChange](https://docs.couchbase.com/mobile/3.2.0/couchbase-lite-android/com/couchbase/lite/QueryChange.html). This allows you to manitpluate the results before returning them.

Couchbase Lite has a different way of handing replication and security than the Atlas Device SDK [Subscription API](https://www.mongodb.com/docs/atlas/device-sdks/sdk/kotlin/sync/subscribe/#subscriptions-overview).  Because of this, some of the code has been simplifed to handle when filtering out the current user tasks vs all tasks in the collection.

> [!IMPORTANT]
>For a production mobile app, make sure you read the Couchbase Capella App Services [channels](https://docs.couchbase.com/cloud/app-services/channels/channels.html) and [roles](https://docs.couchbase.com/cloud/app-services/user-management/create-app-role.html) documentation to understand the security model it provides. 
>
>The Couchbase Lite SDK [Replication Configuration](https://docs.couchbase.com/couchbase-lite/current/android/replication.html#lbl-cfg-repl) API also supports [filtering of channels](https://docs.couchbase.com/couchbase-lite/current/android/replication.html#lbl-repl-chan) to limit the data that is replicated to the device. 

For the conversion of this app, the decision was made to include code that functions similar to the Realm SDK ResultsChange API.  A new interface and class implementations where added to the [ResultsChange.kt](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/data/ResultsChange.kt#L3) file.

```kotlin
interface ResultsChange<T>

class InitialResults<T> : ResultsChange<T> {
    val list: MutableList<T> = mutableListOf()
}

class UpdatedResults<T> : ResultsChange<T> {
    val insertions: MutableList<T> = mutableListOf()
    val deletions: MutableList<T> = mutableListOf()
    val changes: MutableList<T> = mutableListOf()
}
```

> **NOTE**
> This represents a partial implementation of the ResultsChange API. It is designed to maintain the application’s operational integrity without necessitating substantial code rewrites or altering the user experience associated with rendering items in the list during addition or deletion processes.
>

A [_previousItemsMap](https://github.com/couchbaselabs/cbl-realm-template-app-kotlin-todo/blob/main/app/src/main/java/com/mongodb/app/data/SyncRepository.kt#L108) property is defined in the CouchbaseSyncRepository is used to track the previous items that were returned from the getTaskList call so that the changes can be calculated.

```kotlin
private var _previousItemsMap: MutableMap<String, Item> = mutableMapOf()
```

The getTaskList method was implemented using a LiveQuery as shown below:

```kotlin
override fun getTaskList(subscriptionType: SubscriptionType): Flow<ResultsChange<Item>> {
 this._previousItemsMap = mutableMapOf()
 val query = when (subscriptionType) {
   SubscriptionType.MINE -> queryMyTasks
   SubscriptionType.ALL -> queryAllTasks
 }
 val flow = query
    .queryChangeFlow()
    .map { qc -> mapQueryChangeToItem(qc) }
    .flowOn(Dispatchers.IO)
  query.execute()
  return flow
}
```

This code runs a live query based on the SubscriptionType passed into the method, which emulates changing of subscriptions in Realm. The queries were defined in the previous cache query setup section of this document.  

If the subscription mode is configured to filter documents by the current user, the query targets documents where the ownerId field matches the user’s ID. In the case of the “All” mode, it retrieves all documents from the data.items collection, sorted by their document IDs. The query is then executed, returning the results as a Flow of ResultsChange<Item> objects.

The `mapQueryChangeToItem` method is used to convert the QueryChange object to a ResultsChange<Item> object by using the Kotlin serialization library to deserialize the JSON string that is returned from the query.   

```kotlin
 private fun mapQueryChangeToItem(queryChange: QueryChange): ResultsChange<Item> {
  val isInitial = _previousItemsMap.isEmpty()
  val initialResults = InitialResults<Item>()
  val updatedResults = UpdatedResults<Item>()

  // used to track the current items which will
  // become the next previousItemMap after this is complete
  val currentItemsMap = mutableMapOf<String, Item>()

  // used to trim out items
  // anything left over is a deletion
  val previousItemsSet = _previousItemsMap.keys.toMutableSet()
  //loop through the query change results
  queryChange.results?.let { results ->
   results.forEach { result ->
    val item = Json.decodeFromString<ItemDao>(result.toJSON()).item
    currentItemsMap[item.id] = item
    if (isInitial) {
     initialResults.list.add(item)
    } else {
     val previousItem = _previousItemsMap[item.id]
     when {
      previousItem == null -> updatedResults.insertions.add(item)
      item != previousItem -> updatedResults.changes.add(item)
     }
      previousItemsSet.remove(item.id)
     }
    }
   }
   if (!isInitial) {
   // Determine deletions
   previousItemsSet.forEach { id ->
    _previousItemsMap[id]?.let { updatedResults.deletions.add(it) }
   }
  }
  _previousItemsMap.clear()  
  _previousItemsMap.putAll(currentItemsMap)  

  return if (isInitial) initialResults else updatedResults
}
```

> **NOTE**
>To replicate the ResultsChange API from Realm, this code had to calculate the deltas (additions, deletions, and updates) by comparing the current query results with the previous list results. This approach introduces additional complexity and requires more code than the original implementation.  Using the LiveQuery API directly would be more efficient, but each time the data is updated, the entire list would be re-rendered.  This could cause performance issues in the application.  
>
>There are multiple approaches to how to calculate the deltas.  This example will use more memory in order to save CPU cycles, which in testing on physical devices resulted in better performance on older devices with slower processors.
>

### toggleIsComplete method

The toggleIsComplete method is used to update a task.  This is done by retrieving the document from the database using the collection.getDocument method and then updating the document with the new value for the isComplete property.  A security check was added so that only the owner of the task can update the task.

```kotlin
override suspend fun toggleIsComplete(task: Item) {
 withContext(Dispatchers.IO) {
  try {
   val doc = collection.getDocument(task.id)
   doc?.let {
    //handle security of the owner only being able to update their own tasks
    val ownerId = doc.getString("ownerId")
    if (ownerId != task.ownerId) {
      onError(IllegalStateException("User does not have permission to update this task"))
    } else {
      val isComplete = doc.getBoolean("isComplete")
      val mutableDoc = doc.toMutable()
      mutableDoc.setBoolean("isComplete", !isComplete)
      collection.save(mutableDoc)
    }
   }
  } catch (e: Exception) {
    onError(e)
  }
 }
}
```

### TaskViewModel changes

The TaskViewModel init method was updated to use the new LiveQuery data.  

```kotlin
init {
 viewModelScope.launch {
  repository.getTaskList(SubscriptionType.MINE)
  .collect { event: List<Item> ->
    taskListState.clear()
    taskListState.addAll(event)
  }
 }
}
```

### TaskAppToolbar.kt

The method of logging out of the application had to be updated to set the currentUser to null before running the viewModel logOut method. 

```kotlin
CoroutineScope(Dispatchers.IO).launch {
 runCatching {
   app.currentUser = null
 }.onSuccess {
   viewModel.logOut()
 }.onFailure {
   viewModel.error(ToolbarEvent.Error("Log out failed", it))
 }
}
```

### OwnTaskSwitch.kt

The UI component OwnTaskSwitch is used to switch between the current user's tasks and all tasks. It was updated to call the TaskViewModel method to update the task list Live Query. 

```kotlin
Switch(
  ...
  onCheckedChange = {
   if (toolbarViewModel.offlineMode.value) {
     viewModel.showOfflineMessage()
   } else {
     val updatedSubscriptionType = when (viewModel.subscriptionType.value) {
       SubscriptionType.MINE -> SubscriptionType.ALL
       SubscriptionType.ALL -> SubscriptionType.MINE
    }
    viewModel.updateSubscription(updatedSubscriptionType)
    taskViewModel.updateQuerySubscriptionModel(updatedSubscriptionType)
  }
 },
 ...
)
```

More Information
----------------
- [Couchbase Lite for Android documentation](https://docs.couchbase.com/couchbase-lite/current/android/quickstart.html)
- [Couchbase Capella App Services documentation](https://docs.couchbase.com/cloud/app-services/index.html)



Disclaimer
----------
The information provided in this documentation is for general informational purposes only and is provided on an “as-is” basis without any warranties, express or implied. This includes, but is not limited to, warranties of accuracy, completeness, merchantability, or fitness for a particular purpose. The use of this information is at your own risk, and the authors, contributors, or affiliated parties assume no responsibility for any errors or omissions in the content.

No technical support, maintenance, or other services are offered in connection with the use of this information. In no event shall the authors, contributors, or affiliated parties be held liable for any damages, losses, or other liabilities arising out of or in connection with the use or inability to use the information provided.
