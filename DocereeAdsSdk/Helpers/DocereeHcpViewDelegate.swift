
import Foundation
import UIKit

public protocol HcpValidationViewDelegate {
    func hcpValidationViewSuccess(_ hcpValidationView: HcpValidationView)
    func hcpValidationView(_ hcpValidationView: HcpValidationView,
                       didFailToReceiveHcpWithError error: HcpRequestError)
    func hcpPopupAction(_ popupAction: PopupAction)
}

public extension HcpValidationViewDelegate {
    func hcpValidationViewSuccess(_ hcpValidationView: HcpValidationView) {}
    func hcpValidationView(_ hcpValidationView: HcpValidationView,
                       didFailToReceiveHcpWithError error: HcpRequestError) {}
    func hcpPopupAction(_ popupAction: PopupAction) {}
}
