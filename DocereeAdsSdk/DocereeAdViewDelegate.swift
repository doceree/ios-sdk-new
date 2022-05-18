
import Foundation
import UIKit

public protocol DocereeAdViewDelegate{
    func docereeAdViewDidReceiveAd(_ docereeAdView: DocereeAdView)
    func docereeAdView(_ docereeAdView: DocereeAdView,
                       didFailToReceiveAdWithError error: DocereeAdRequestError)
    func docereeAdViewWillPresentScreen(_ docereeAdView: DocereeAdView)
    func docereeAdViewWillDismissScreen(_ docereeAdView: DocereeAdView)
    func docereeAdViewDidDismissScreen(_ docereeAdView: DocereeAdView)
    func docereeAdViewWillLeaveApplication(_ docereeAdView: DocereeAdView)
}

public extension DocereeAdViewDelegate{
    func docereeAdViewDidReceiveAd(_ docereeAdView: DocereeAdView) {}
    func docereeAdView(_ docereeAdView: DocereeAdView,
                       didFailToReceiveAdWithError error: DocereeAdRequestError) {}
    func docereeAdViewWillPresentScreen(_ docereeAdView: DocereeAdView) {}
    func docereeAdViewWillDismissScreen(_ docereeAdView: DocereeAdView) {}
    func docereeAdViewDidDismissScreen(_ docereeAdView: DocereeAdView) {}
    func docereeAdViewWillLeaveApplication(_ docereeAdView: DocereeAdView) {}
}
