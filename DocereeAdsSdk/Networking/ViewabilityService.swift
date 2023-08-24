//
//  ViewabilityService.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 18/08/23.
//

import Foundation

final class ViewabilityService {
    
    init() {
        
    }
    
    func sendAdViewability(viewLink: String) {
        print("sendAdViewability: ", viewLink)
        let updatedUrl: String? = viewLink
        let url: URL = URL(string: updatedUrl!)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HttpMethod.get.rawValue
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        let task = session.dataTask(with: urlRequest){ (data, response, error) in
            guard data != nil else { return }
            let urlResponse = response as! HTTPURLResponse
            print("viewability sent. Http Status code is \(urlResponse.statusCode)")
        }
        task.resume()
    }
    
    
}
