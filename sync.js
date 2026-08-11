function (doc, oldDoc, meta) {

  var ownerId = doc._deleted ? (oldDoc && oldDoc.ownerId) : doc.ownerId;

  if (ownerId != null) {
    // Only the owner may write or delete their own task.
    requireUser(ownerId);

    // Assign the document to the public channel, "!". All users have automatic
    // access to the public channel, so every user can read every task.
    // To restrict reads instead, route to a per-user channel here and grant access
    // to it with the access() API, e.g.:
    //   channel("user-" + ownerId);
    //   access(ownerId, "user-" + ownerId);
    channel("!");
  } else {
    throw({ forbidden: "Document rejected as it does not have ownerId " });
  }
}
