//
//  AuthenticationService.swift
//  App
//
//  Created by Aaron LaBeau on 10/10/24.
//

import Foundation

public class AuthenticationService : NSObject {
    
    private override init () { }
    
    //create a singleton
    static let shared:AuthenticationService = {
        let instance = AuthenticationService()
        return instance
    }()
    
    func login(username: String, password: String) async throws -> User?
    {
        let httpsUrl = appConfig.endpointUrl.replacingOccurrences(of: "wss://", with: "https://")
        let checkUrl = httpsUrl.replacingOccurrences(of: "/tasks", with: "/")
        
        guard isUrlReachable(urlString: checkUrl) else {
            throw ConnectionException(message: "Could not reach the endpoint URL.")
        }
        guard let url = URL(string: httpsUrl) else {
            throw URLError(.badURL)
        }
        let auth = "\(username):\(password)"
        let encodedAuth = Data(auth.utf8).base64EncodedString()
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(encodedAuth)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        //let (data, response) = try await URLSession.shared.data(for: request)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
            case 200:
                return User(username: username, password: password)
            case 401:
                if let responseBody = String(data: data, encoding: .utf8) {
                    print("Http Reponse: \(httpResponse)")
                    print("Error Response Body: \(responseBody)")
                }
                //throw InvalidCredentialsException(message: "Invalid username or password.")
                return User(username: username, password: password)
            default:
                throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil)
        }
    }
    
    private func isUrlReachable(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        let semaphore = DispatchSemaphore(value: 0)
        var isReachable = false
        
        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                isReachable = true
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        return isReachable
    }
    
    //debug headers
    private static func printRequestHeaders(_ request: URLRequest) {
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                print("\(key): \(value)")
            }
        } else {
            print("No headers found.")
        }
    }
}

extension AuthenticationService: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Trust all certificates (for debugging purposes only)
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
