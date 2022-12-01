//
//  ImageLoader.swift
//  DocereeAdsSdk
//
//  Created by Muqeem.Ahmad on 01/12/22.
//

import UIKit

class ImageLoader {

    class var sharedInstance : ImageLoader {
        struct Static {
            static let instance : ImageLoader = ImageLoader()
        }
        return Static.instance
    }
    
    func imageForUrl(urlString: String, completionHandler:@escaping (_ image: UIImage?) -> ()) {
        let downloadTask: URLSessionDataTask = URLSession.shared.dataTask(with: URL.init(string: urlString)!) { (data, response, error) in
            if error == nil {
                if data != nil {
                    let image = UIImage.init(data: data!)
                    DispatchQueue.main.async {
                        completionHandler(image)
                    }
                }
            } else {
                completionHandler(nil)
            }
        }
        downloadTask.resume()
    }
}
