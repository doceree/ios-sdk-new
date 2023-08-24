//
//  ImpressionService.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 18/08/23.
//

import Foundation

final class ImpressionService {
    
    init() {
        
    }
    
    func sendAdImpression(impressionUrl: String) {
        let updatedUrl: String? = impressionUrl
        let url: URL = URL(string: updatedUrl!)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HttpMethod.get.rawValue
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)

        let task = session.dataTask(with: urlRequest){ (data, response, error) in
            guard data != nil else { return }
            let urlResponse = response as! HTTPURLResponse
            print("impression sent. Http Status code is \(urlResponse.statusCode)")
        }
        task.resume()
    }

}
