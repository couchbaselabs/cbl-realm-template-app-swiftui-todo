function (doc, oldDoc, meta) {
	// Check if ownerId exists. You can optionally add validation for other parameters
	 if (doc.ownerId != null) {
	   // Check that the user updating document is the owner of the document
	   // All doc updates via Capella are treated as admin user and will bypass requireUser() check
	   requireUser (doc.ownerId);
	   // Assign the document to public channel,"!". All users have automatic access to documents in
	   // public channel. 
	   // If you want to restrict user access to a specific channel you can specify that here and 
	   // then grant user access to that channel via access() API
	   channel ("!");
	 }
	 else {
	   // If no ownerId, reject the document
		 throw({forbidden:"Document rejected as it does not have ownerId "});
	 }
   }