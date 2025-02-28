
import UIKit


extension DocereeAdRequestError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .failedToCreateRequest: return NSLocalizedString("Failed to load ad. Please contact support@doceree.com", comment: "")
        case .adNotFound:
            return NSLocalizedString("Ad not found", comment: "")
        }
    }
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
//    convenience init(hex: String) {
//        let hexValue = Int(hex, radix: 16) ?? 0
//        let red = CGFloat((hexValue >> 16) & 0xFF) / 255.0
//        let green = CGFloat((hexValue >> 8) & 0xFF) / 255.0
//        let blue = CGFloat(hexValue & 0xFF) / 255.0
//        self.init(red: red, green: green, blue: blue, alpha: 1.0)
//    }
}

extension NSData {
    var imageFormat: ImageFormat {
        var buffer = [UInt8](repeating: 0, count: 1)
        self.getBytes(&buffer, range: NSRange(location: 0, length: 1))
        if buffer == ImageHeaderData.GIF {
            return .GIF
        } else if buffer == ImageHeaderData.JPEG {
            return .JPEG
        } else if buffer == ImageHeaderData.PNG{
            return .PNG
        } else if buffer == ImageHeaderData.TIFF_01 || buffer == ImageHeaderData.TIFF_02 {
            return .TIFF
        } else {
            return .Unknown
        }
    }
}

extension NotificationCenter {
    func setObserver(observer: Any, selector: Selector, name: NSNotification.Name, object: AnyObject?){
        NotificationCenter.default.removeObserver(observer, name: name, object: object)
        NotificationCenter.default.addObserver(observer, selector: selector, name: name, object: object)
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        // Starts from next (As we know self is not a UIViewController).
        var parentResponder: UIResponder? = self.next
        while parentResponder != nil {
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
            parentResponder = parentResponder?.next
        }
        return nil
    }
}

extension UIView {
    var lastViewObject: AnyObject? {
        // Starts from next (As we know self is not a UIViewController).
        var parentResponder: UIResponder? = self.next
        var lastObject: AnyObject?
        while parentResponder != nil {
            if parentResponder is UIViewController {
                return lastObject // return last object before viewController
//                return viewController
            }
            lastObject = parentResponder
            parentResponder = parentResponder?.next
        }
        return nil
    }
}

extension UIView {
    var scrollviewObject: UIScrollView? {
        // Starts from next (As we know self is not a UIViewController).
        var parentResponder: UIResponder? = self.next
        while parentResponder != nil {
            if parentResponder is UIScrollView {
                return parentResponder as? UIScrollView
            }
            parentResponder = parentResponder?.next
        }
        return nil
    }
}

extension UIView {

    // there can be other views between `subview` and `self`
    func getConvertedFrame(fromSubview subview: UIView) -> CGRect? {
        // check if `subview` is a subview of self
        guard subview.isDescendant(of: self) else {
            return nil
        }
        
        var frame = subview.frame
        if subview.superview == nil {
            return frame
        }
        
        var superview = subview.superview
        while superview != self {
            frame = superview!.convert(frame, to: superview!.superview)
            if superview!.superview == nil {
                break
            } else {
                superview = superview!.superview
            }
        }
        
        return superview!.convert(frame, to: self)
    }

}

extension UIView {
    func getPosition(parent: UIView) -> CGPoint {
        var originOnWindow: CGPoint { return convert(CGPoint.zero, to: parent) }
        return originOnWindow
    }
}

extension UITableView {
    var originOnWindowUT: CGPoint { return convert(contentOffset, to: nil) }
}

extension UIView {
    var globalFrame: CGRect {
        return convert(bounds, to: window)
    }
}
