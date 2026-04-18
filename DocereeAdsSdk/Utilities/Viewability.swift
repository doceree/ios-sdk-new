
import UIKit

func checkViewability(adView: UIView) -> Float {
    if let parentView = adView.scrollviewObject {
//        print("ScrollView found")
        let viewPercentage = viewabilityPercentageScrollView(adView: adView, scrollView: parentView)
        return Float(viewPercentage)
    } else {
        let parentVC = adView.parentViewController
        let frame = parentVC?.view.getConvertedFrame(fromSubview: adView)
        if let vFrame = frame {
            let viewPercentage = viewabilityPercentage(viewFrame: vFrame)
            return Float(viewPercentage)
        }
    }
    return 0.0
}

func viewabilityPercentage(viewFrame: CGRect) -> CGFloat {
    
    let screenSize: CGRect = UIScreen.main.bounds
    
    // for vertical visibility
    var verticalPercentage = 0.0
    if viewFrame.minY < 0 {
        let visibleHeight = viewFrame.height - abs(viewFrame.minY)
        if visibleHeight > 0 {
            verticalPercentage = (visibleHeight / viewFrame.height) * 100
//            print("bottom portion percentage: ", verticalPercentage)
        } else {
//            print("hidden at top")
            return 0.0
        }
    } else if viewFrame.minY > screenSize.maxY {
//        print("hidden at bottom")
        return 0.0
    } else {
        if viewFrame.maxY > screenSize.maxY {
            let hiddenHeight = viewFrame.maxY - screenSize.maxY
            let visibleHeight = viewFrame.height - hiddenHeight
            verticalPercentage = (visibleHeight / viewFrame.height) * 100
//            print("top portion percentage: ", verticalPercentage)
        } else {
            verticalPercentage = 100.0
//            print("Full add vertically")
        }
    }

    // for horizontal visibility
//    var horizontalPercentage = 0.0
//    if viewFrame.minX < 0 {
//        let visibleWidth = viewFrame.width - abs(viewFrame.minX)
//        if visibleWidth > 0 {
//            horizontalPercentage = (visibleWidth / viewFrame.width) * 100
//            print("right portion percentage: ", horizontalPercentage)
//        } else {
//            print("hidden at left")
//            return 0.0
//        }
//    } else if viewFrame.minX > screenSize.maxX {
//        print("hidden at right")
//        return 0.0
//    } else {
//        if viewFrame.maxX > screenSize.maxX {
//            let hiddenWidth = viewFrame.maxX - screenSize.maxX
//            let visibleWidth = viewFrame.width - hiddenWidth
//            horizontalPercentage = (visibleWidth / viewFrame.width) * 100
//            print("left portion percentage: ", horizontalPercentage)
//        } else {
//            horizontalPercentage = 100.0
//            print("Full add horizontally")
//        }
//    }
//
//    return max(verticalPercentage, horizontalPercentage)
    return verticalPercentage
}

func viewabilityPercentageScrollView(adView: UIView, scrollView: UIScrollView) -> Float {
    let screenSize: CGRect = UIScreen.main.bounds
    let offset: CGPoint? = scrollView.contentOffset
    let adCurrentPos = scrollView.getConvertedFrame(fromSubview: adView)
    
    //
    let parentVC = scrollView.parentViewController
    let scrollViewPos = parentVC?.view.getConvertedFrame(fromSubview: scrollView)

    let currentAdX =  adCurrentPos!.minX - offset!.x
    let currentAdY =  adCurrentPos!.minY - offset!.y
//    print("currentAdX: \(currentAdX), currentAdY: \(currentAdY)")
    
    var visibleHeight = 0.0
    if (currentAdY + adView.frame.height) < 0 {
//        print("hidden at top: ")
    } else if currentAdY < 0 {
        if scrollViewPos!.minY > 0 {
            let yWithScreen = scrollViewPos!.minY - offset!.y + adCurrentPos!.minY
            if screenSize.height - yWithScreen > adView.frame.height {
                visibleHeight = adView.frame.height + currentAdY
//                verticalPercentage = (visibleHeight / adView.frame.height) * 100
//                print("bottom portion ", visibleHeight)
            } else {
                print("mid portion ")
            }
        } else {
            visibleHeight = adView.frame.height + currentAdY
//            verticalPercentage = (visibleHeight / adView.frame.height) * 100
//            print("bottom portion ", visibleHeight)
        }
    } else {
        var topBarHeight = 0.0 // In case of top bar we have to calculate viewability from the top bar
        if let navBarHeight = adView.parentViewController?.navigationController?.navigationBar.frame.height {
            topBarHeight = statusBarHeight + navBarHeight
        }
        
        var vcY = 0.0 // In case of automatic view presentaiotn we have to skip that heihgt gap
        if let viewHeight = adView.parentViewController?.view.frame.maxY {
            let heightDiff = UIScreen.main.bounds.height - viewHeight
            vcY = heightDiff
        }
        
        visibleHeight = (screenSize.height - scrollViewPos!.minY) - currentAdY - topBarHeight - vcY
        if visibleHeight > adView.frame.height {
//            print("Full add vertically")
            visibleHeight = adView.frame.height
        } else {
            if visibleHeight < 0 {
                visibleHeight = 0
//                print("hidden at bottom: ")
            } else {
//                verticalPercentage = (visibleHeight / adView.frame.height) * 100
//                print("top portion: \(visibleHeight)")
            }
        }
    }
//    return Float(verticalPercentage)
    
    var visibleWidth = 0.0
    if (currentAdX + adView.frame.width) < 0 {
//        print("hidden at left: ")
    } else if currentAdX < 0 {
        if scrollViewPos!.minX > 0 {
            let xWithScreen = scrollViewPos!.minX - offset!.x + adCurrentPos!.minX
            if screenSize.width - xWithScreen > adView.frame.width {
                visibleWidth = adView.frame.width + currentAdX
//                horizontalPercentage = (visibleWidth / adView.frame.width) * 100
//                print("right portion ", visibleWidth)
            } else {
                print("mid portion ")
            }
        } else {
            visibleWidth = adView.frame.width + currentAdX
//            horizontalPercentage = (visibleWidth / adView.frame.width) * 100
//            print("right portion ", visibleWidth)
        }
    } else {
        visibleWidth = (screenSize.width - scrollViewPos!.minX) - currentAdX
        if visibleWidth > adView.frame.width {
            visibleWidth = adView.frame.width
//            print("Full add horizontally")
        } else {
            if visibleWidth < 0 {
                visibleWidth = 0
//                print("hidden at right: ")
            } else {
//                horizontalPercentage = (visibleWidth / adView.frame.width) * 100
//                print("left portion: \(visibleWidth)")
            }
        }
    }

    let visiblePercentage = ((visibleWidth * visibleHeight) / (adView.frame.width * adView.frame.height)) * 100
    return Float(visiblePercentage)
}
