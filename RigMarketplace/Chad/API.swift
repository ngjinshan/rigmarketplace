//
//  API.swift
//  RigMarketplace
//
//  Created by Jin Shan Ng on 18/05/2023.
//

import Foundation

/**
 @params:
 query: question from user
 @return:
 String: reply from chatgpt
 */
func chatGPT(query: String) async -> String{
    
    guard let url = URL(string: "https://chatgpt53.p.rapidapi.com/") else {
        print("Invalid URL")
        return ""
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue(Constants.RAPID_API_KEY, forHTTPHeaderField: "X-RapidAPI-Key")
    request.addValue(Constants.RAPID_API_HOST, forHTTPHeaderField: "X-RapidAPI-Host")
    
//    let data = [
//        "role": "user",
//        "content": query
//    ]
    
    let data: [String: Any] = [
        "messages": [
        [
            "role": "user",
            "content": query
        ]
        ]
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
    } catch {
        print("Failed to serialize JSON data: \(error)")
        return "Something went wrong"
    }
    
    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "", code: -1, userInfo: nil)
        }
        
        //decode
        if let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        
        return "Something went wrong"
    } catch {
        print("Failed to request \(error)")
        return "Something went wrong"
    }
}
