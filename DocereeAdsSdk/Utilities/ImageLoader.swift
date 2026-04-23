
import UIKit

class ImageLoader {

    class var sharedInstance : ImageLoader {
        struct Static {
            static let instance : ImageLoader = ImageLoader()
        }
        return Static.instance
    }
    
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        Task {
            var request = URLRequest(url: url)
            request.timeoutInterval = DocereeHTTPTimeouts.interactiveRequest
            do {
                let (data, _) = try await DocereeURLSessionLoading.dataWithInteractiveRetries(for: request)
                let image = UIImage(data: data)
                await MainActor.run {
                    completion(image)
                }
            } catch {
                DocereeLog.debug(error.localizedDescription)
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }
    
}
