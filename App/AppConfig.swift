import Foundation

/// Store the Capella app details to use when instantiating the app and start authentication
struct AppConfig {
    var endpointUrl: String
    var capellaUrl: String
}

/// Read the atlasConfig.plist file and store the app ID and baseUrl to use elsewhere.
func loadAppConfig() -> AppConfig {
    guard let path = Bundle.main.path(forResource: "capellaConfig", ofType: "plist") else {
        fatalError("Could not load atlasConfig.plist file!")
    }
    // Any errors here indicate that the capellaConfig.plist file has not been formatted properly.
    // Expected key/values:
    //      "endpointUrl": "your App Services URL"
    let data = NSData(contentsOfFile: path)! as Data
    let capellaConfigPropertyList = try! PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]
    let endpointUrl = capellaConfigPropertyList["endpointUrl"]! as! String
    let capellaUrl = capellaConfigPropertyList["capellaUrl"]! as! String

    return AppConfig(endpointUrl: endpointUrl, capellaUrl: capellaUrl)
}
