
import UIKit

class AdsRefreshCountdownTimer {
    
    var timer: Timer?
    // new backward compatible implementation
    let adRefreshRepeatInterval = 30.0
    
    static let shared = AdsRefreshCountdownTimer()
    
    private init() {
    }
    
    // MARK: Create timer here
    private func createTimer(completion : @escaping() -> Void) {
        if timer == nil {
            // new backward compatible implementation
            if #available(iOS 10, *){
                timer = Timer.scheduledTimer(withTimeInterval: self.adRefreshRepeatInterval, repeats: true){ _ in
                    completion()
                }
            } else {
                timer = Timer.scheduledTimer(timeInterval: self.adRefreshRepeatInterval, target: self, selector: #selector(completionCallback), userInfo: nil, repeats: true)
            }
        }
    }
    
    @objc func completionCallback(completion: @escaping() -> Void) {
        completion()
    }
        
    // MARK: Start refresh
    func startRefresh(completion : @escaping() -> Void) {
        // create timer here
        createTimer(completion: completion)
    }
    
    // MARK: Stop refresh
    func stopRefresh() {
        cancelTimer()
    }
    
    // MARK: Cancel the timer
    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
    
}
