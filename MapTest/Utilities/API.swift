//
//  API.swift
//  MapTest
//
//  Created by Amir Shayegh on 2020-03-02.
//  Copyright © 2020 Amir Shayegh. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import Reachability

class API {
    
    private init() {}
    
    // MARK: GET request
    public static func get(endpoint: URL, completion: @escaping (_ response: JSON?) -> Void) {
        // Reachability
        do {
            let reacahbility = try Reachability()
            if (reacahbility.connection == .unavailable) {
                return completion(nil)
            }
        } catch  let error as NSError {
            print("** Reachability ERROR")
            print(error)
            return completion(nil)
        }
        
        // Manual 20 second timeout for each call
        var completed = false
        var timedOut = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if !completed {
                timedOut = true
                return completion(nil)
            }
        }
        
        let configuration = URLSessionConfiguration.default
        // disable default credential store
        configuration.urlCredentialStorage = nil
        _ = Alamofire.SessionManager(configuration: configuration)
        
        // Make the call
        _ = Alamofire.request(endpoint, method: .get).responseData { (response) in
            completed = true
            if timedOut {return}
            
            guard response.result.description == "SUCCESS", let value = response.result.value else {
                return completion(nil)
            }
            let json = JSON(value)
            if let error = json["error"].string {
                print("GET call rejected:")
                print("Endpoint: \(endpoint)")
                print("Error: \(error)")
                return completion(nil)
            } else {
                // Success
                return completion(json)
            }
            
        }
        //        debugPrint(req)
    }
    
    public static func post(endpoint: URL, params: [String: Any], completion: @escaping (_ response: JSON?) -> Void) {
        // Manual 20 second timeout for each call
        var completed = false
        var timedOut = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if !completed {
                timedOut = true
                return completion(nil)
            }
        }
        
        // Request
        _ = Alamofire.request(endpoint, method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { response in
            completed = true
            if timedOut {return}
            guard response.result.description == "SUCCESS", let value = response.result.value else {
                return completion(nil)
            }
            let json = JSON(value)
            if let error = json["error"].string {
                print("POST call rejected:")
                print("Endpoint: \(endpoint)")
                print("Error: \(error)")
                return completion(nil)
            } else {
                // Success
                return completion(json)
            }
        }
    }
}
