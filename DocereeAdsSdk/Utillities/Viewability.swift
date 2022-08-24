
import UIKit

func checkViewability(adView: UIView) -> Float {
    
//    if let tableCell = adView.superview as? UITableViewCell {
//        let tv = tableCell.superview as! UITableView
//        let positionOnWindow = adView.getPosition(parent: tv)
//        let viewPercentage = viewabilityPercentageNewTable(view: adView, viewFrame: positionOnWindow, tableView: tv)
//        return Float(viewPercentage)
//    } else
    if adView.scrollviewObject is UIScrollView {
        print("ScrollView found")
        let scrollView = adView.scrollviewObject
        let viewPercentage = viewabilityPercentageScrollView(adView: adView, scrollView: scrollView!)
        return Float(viewPercentage)
    } else {
        let parentVC = adView.parentViewController
        let frame = parentVC?.view.getConvertedFrame(fromSubview: adView)
        print("bounds", frame as Any)
        if let vFrame = frame {
            let viewPercentage = viewabilityPercentage(viewFrame: vFrame)
            return Float(viewPercentage)
        }
    }
    
    return 0.0
}

//func tableViewabilityPercentage(viewFrame: CGRect, tableView: UITableView) -> CGFloat {
//
//
//    if tableView.contentOffset.y == 0 {
//        if viewFrame.maxY < tableView.frame.height {
//            print("percentage", 100)
//        } else if viewFrame.minY < tableView.frame.height {
//
//            let hidePixels = viewFrame.maxY - tableView.frame.height
//            let viewingHeight = viewFrame.height - hidePixels
//            let percentage = (viewingHeight / viewFrame.height) * 100
//            print("percentage", percentage)
//        } else {
//            print("hidePixels", 0.0)
//        }
//    } else if (viewFrame.minY - tableView.contentOffset.y) <= 0 {
//        let currentY =  -(tableView.contentOffset.y - viewFrame.minY)
//        if currentY < 0 {
//            if -currentY > viewFrame.height {
//                print("percentage", 0)
//            } else {
//                let viewableHeight =  viewFrame.height + currentY
//                let percentage = (viewableHeight / viewFrame.height) * 100
//                print("percentage", percentage)
//            }
//        }
//    } else if (viewFrame.minY - tableView.contentOffset.y) > tableView.frame.height {
//        let yDiff = viewFrame.maxY - tableView.frame.height
//        let viewingHeight = viewFrame.height - yDiff
//        if viewingHeight < 0 {
//            return 0.0
//        }
//        let percentage = (viewingHeight / viewFrame.height) * 100
//        print("percentage", percentage)
//    } else if (viewFrame.minY - tableView.contentOffset.y) < tableView.frame.height {
//        let yDiff = tableView.frame.height - (viewFrame.minY - tableView.contentOffset.y)
//        let viewingHeight = yDiff
//        if viewingHeight < 0 {
//            return 0.0
//        } else if viewingHeight >= viewFrame.height {
//            print("percentage", 100)
//        } else {
//            let percentage = (viewingHeight / viewFrame.height) * 100
//            print("percentage", percentage)
//        }
//    } else {
//        print("percentage blank")
//    }
//
//
//    return 0.0
//}

func viewabilityPercentage(viewFrame: CGRect) -> CGFloat {
    
    let screenSize: CGRect = UIScreen.main.bounds
    
    // for vertical visibility
    var verticalPercentage = 0.0
    if viewFrame.minY < 0 {
        let visibleHeight = viewFrame.height - abs(viewFrame.minY)
        if visibleHeight > 0 {
            verticalPercentage = (visibleHeight / viewFrame.height) * 100
            print("bottom portion percentage: ", verticalPercentage)
        } else {
            print("hidden at top")
            return 0.0
        }
    } else if viewFrame.minY > screenSize.maxY {
        print("hidden at bottom")
        return 0.0
    } else {
        if viewFrame.maxY > screenSize.maxY {
            let hiddenHeight = viewFrame.maxY - screenSize.maxY
            let visibleHeight = viewFrame.height - hiddenHeight
            verticalPercentage = (visibleHeight / viewFrame.height) * 100
            print("top portion percentage: ", verticalPercentage)
        } else {
            verticalPercentage = 100.0
            print("Full add vertically")
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

func viewabilityPercentageNewTable(view: UIView, viewFrame: CGPoint, tableView: UITableView) -> Float {
    
    print("test", viewFrame.y - tableView.contentOffset.y)
    let hiddenPixels =  tableView.contentOffset.y - viewFrame.y
//    print("hiddenPixels: ", hiddenPixels)
    if (viewFrame.y + view.frame.height) > (tableView.frame.height + tableView.contentOffset.y) {
        let viewableHeight =  (tableView.frame.height + tableView.contentOffset.y) - viewFrame.y
        if viewableHeight < 0 {
            print("Full hidden below the view")
        } else {
            let percentage = (viewableHeight / view.frame.height) * 100
            print("percentage on top : \(percentage) %")
            return Float(percentage)
        }
    } else if hiddenPixels > view.frame.height {
        print("Full hidden above the view")
    } else if hiddenPixels < 0 {
        print("Full view")
        return Float(100)
    } else {
        let viewingHeight = view.frame.height - hiddenPixels
        let percentage = (viewingHeight / view.frame.height) * 100
        print("percentage on bottom : \(percentage) %")
        return Float(percentage)
    }

    return 0.0
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
    print("currentAdX: \(currentAdX), currentAdY: \(currentAdY)")
    
    var visibleHeight = 0.0
    if (currentAdY + adView.frame.height) < 0 {
        print("hidden at top: ")
    } else if currentAdY < 0 {
        if scrollViewPos!.minY > 0 {
            let yWithScreen = scrollViewPos!.minY - offset!.y + adCurrentPos!.minY
            if screenSize.height - yWithScreen > adView.frame.height {
                visibleHeight = adView.frame.height + currentAdY
//                verticalPercentage = (visibleHeight / adView.frame.height) * 100
                print("bottom portion ", visibleHeight)
            } else {
                print("mid portion ")
            }
        } else {
            visibleHeight = adView.frame.height + currentAdY
//            verticalPercentage = (visibleHeight / adView.frame.height) * 100
            print("bottom portion ", visibleHeight)
        }
    } else {
        visibleHeight = (screenSize.height - scrollViewPos!.minY) - currentAdY
        if visibleHeight > adView.frame.height {
            print("Full add vertically")
            visibleHeight = adView.frame.height
        } else {
            if visibleHeight < 0 {
                visibleHeight = 0
                print("hidden at bottom: ")
            } else {
//                verticalPercentage = (visibleHeight / adView.frame.height) * 100
                print("top portion: \(visibleHeight)")
            }
        }
    }
//    return Float(verticalPercentage)
    
    var visibleWidth = 0.0
    if (currentAdX + adView.frame.width) < 0 {
        print("hidden at left: ")
    } else if currentAdX < 0 {
        if scrollViewPos!.minX > 0 {
            let xWithScreen = scrollViewPos!.minX - offset!.x + adCurrentPos!.minX
            if screenSize.width - xWithScreen > adView.frame.width {
                visibleWidth = adView.frame.width + currentAdX
//                horizontalPercentage = (visibleWidth / adView.frame.width) * 100
                print("right portion ", visibleWidth)
            } else {
                print("mid portion ")
            }
        } else {
            visibleWidth = adView.frame.width + currentAdX
//            horizontalPercentage = (visibleWidth / adView.frame.width) * 100
            print("right portion ", visibleWidth)
        }
    } else {
        visibleWidth = (screenSize.width - scrollViewPos!.minX) - currentAdX
        if visibleWidth > adView.frame.width {
            visibleWidth = adView.frame.width
            print("Full add horizontally")
        } else {
            if visibleWidth < 0 {
                visibleWidth = 0
                print("hidden at right: ")
            } else {
//                horizontalPercentage = (visibleWidth / adView.frame.width) * 100
                print("left portion: \(visibleWidth)")
            }
        }
    }

    let visiblePercentage = ((visibleWidth * visibleHeight) / (adView.frame.width * adView.frame.height)) * 100
    return Float(visiblePercentage)
}
