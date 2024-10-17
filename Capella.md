# Setup Couchbase Capella App Services
This guide provides step-by-step instructions for configuring a Couchbase Capella App Services instance, which the mobile application will utilize to store and retrieve data from the cloud.  

## Sign up for free account

Follow the full set of directions for [setting up a free account](https://docs.couchbase.com/cloud/get-started/create-account.html).

## Create new Bucket/Scope/Collection for Data Storage

In these directions, we will create a new Bucket, Scope, and Collection for storing data.  When you log into Capella you should be at the Operational Cluster tab.  Click on cluster listed in the provided cluster listing.  The Home tab will appear and a listing of options should be presented. 

Click on the Data Tools tab.  Once there, click the "+ Create" button on the left side of the navigation menu to create a new Scope and Collection. 

The "Create a Bucket, Scope, and Collection" dialog will appear.  Enter the following information:

1. Select "New" and enter a bucket name in in the New Bucket Name field.  For example, enter `Todo`

2. For Scope, select New and enter the name of `data`

3. For Collection, select New and enter the name `tasks`

Click the Create button to create the new Scope and Collection.


## Setup App Services instance

Once you have followed the directions for setting up your cluster, follow the [directions for setting up App Services](https://docs.couchbase.com/cloud/get-started/create-account.html#app-services).

## Setup App Services Endpoint

Click the App Services tab and select your created App Service from the Setup App Service Instance step.  The App Endpoints listing should appear.  Click on the + Create App Endpoint to create a new endpoint.

When the Create App Endpoint screen appears enter the following information based on the new bucket you created above:

- For the Name field enter `tasks`
- For the Bucket, select `Todo`
- For the Scope, select `data`
- Under "Choose collections to link", select the Link option for the `tasks` collection

Click the Create button to create the new App Endpoint.  Note it may take a few minutes for your App Endpoint to be created. 

## Setup Access Control and Validation

From the App Endpoints list, click on your newly created App Endpoint `tasks`.  From the Access Control and Validation screen, click the linked collections `tasks`.  Follow the following steps:

- Click the Import from File button.  
- Browse to the repo where you downloaded the code and select the sync.js file located in the root of the project.  Click the Import button to import the Sync Function. 
- Click the Save button to save the Sync Function.
- Once the alert is displayed that the Sync Function was saved, click the Settings tab.
- Click the `Resume App Endpoint` button under the Resume App Endpoint section. 

## Setup App Endpoint Users

Click on the Security tab.  Now click on the App Users tab from the navigation menu on the left and then click the "+ Create App Users" button.

Enter the following information:

- For the App User Name enter: `demo1@example.com`
- For the App User Password enter:  `P@ssw0rd12`

Click the chevron for "Configure Access Grants".  Click the "Create App User" button to create the App User.

Follow these steps to create a second App User with the following information:

- For the App User Name enter: `demo2@example.com`
- For the App User Password enter:  `P@ssw0rd12`

> [!WARNING]
> The password is set to `P@ssw0rd12` for demonstration purposes.  This password is in this document, which means anyone on the internet will know it.  You should use a more secure password for your application. 
>

## Get App Endpoint Connection Information

From the App Endpoints section, click on the Connect tab.  The Connect Information screen will appear.  

Copy the Public Connection URL that is provided.  This will be used in the mobile application to connect to the App Endpoint.

Now open the `capellaConfig.plist` file, which is located in the App folder.

Update the `endpointUrl` value with the Public Connection URL you copied from the App Endpoint.  
