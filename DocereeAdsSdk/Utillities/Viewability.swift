
import UIKit

func checkViewability(adView: UIView) -> Float {
    
//    if let tableCell = adView.superview as? UITableViewCell {
//        let tv = tableCell.superview as! UITableView
//        let positionOnWindow = adView.getPosition(parent: tv)
//        let percentage = viewabilityPercentageNewTable(view: adView, viewFrame: positionOnWindow, tableView: tv)
//
//    } else if adView.scrollviewObject is UIScrollView {
        print("ScrollView found")
        let scrollView = adView.scrollviewObject
        let percentage = viewabilityPercentageScrollView(adView: adView, scrollView: scrollView!)
//    } else {
//        let parentVC = adView.parentViewController
//        let frame = parentVC?.view.getConvertedFrame(fromSubview: adView)
//        print("bounds", frame as Any)
//        if let vFrame = frame {
//            let viewPercentage = viewabilityPercentage(viewFrame: vFrame)
//        }
//    }
    
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
    if viewFrame.minY < 0 {
        let yDiff = screenSize.maxY - viewFrame.minY
        let viewingHeight = viewFrame.height - yDiff
        let percentage = (viewingHeight / viewFrame.height) * 100
        print("percentage", percentage)
    } else if viewFrame.maxY > screenSize.maxY {
        let yDiff = viewFrame.maxY - screenSize.maxY
        let viewingHeight = viewFrame.height - yDiff
        if viewingHeight < 0 {
            print("hidden")
            return 0.0
        }
        let percentage = (viewingHeight / viewFrame.height) * 100
        print("percentage", percentage)
    } else if (viewFrame.maxY - screenSize.maxY) > 0 {
        let yDiff = viewFrame.maxY - screenSize.maxY
        let viewingHeight = viewFrame.height - yDiff
        if viewingHeight < 0 {
            return 0.0
        }
        let percentage = (viewingHeight / viewFrame.height) * 100
        print("percentage", percentage)
    } else {
        print("percentage", 100.0)
    }

    
    return 0.0
}

func viewabilityPercentageNewTable(view: UIView, viewFrame: CGPoint, tableView: UITableView) -> Float {
    
    print("test", viewFrame.y - tableView.contentOffset.y)
    let hiddenPixels =  tableView.contentOffset.y - viewFrame.y
//    print("hiddenPixels: ", hiddenPixels)
    if (viewFrame.y + view.frame.height) > (tableView.frame.height + tableView.contentOffset.y) {
        let viewingHeight =  (tableView.frame.height + tableView.contentOffset.y) - viewFrame.y
        if viewingHeight < 0 {
            print("Full hidden below the view")
        } else {
            let percentage = (viewingHeight / view.frame.height) * 100
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
    
    if (currentAdX + adView.frame.width) < 0 {
        print("hidden at left: ")
    } else if currentAdX < 0 {
        if scrollViewPos!.minX > 0 {
            let xWithScreen = scrollViewPos!.minX - offset!.x + adCurrentPos!.minX
            if screenSize.width - xWithScreen > adView.frame.width {
                print("right portion ", adView.frame.width + currentAdX)
            } else {
                print("mid portion ")
            }
        } else {
            print("right portion ", adView.frame.width + currentAdX)
        }
    } else {
        let remainingScreenWidth = (screenSize.width - scrollViewPos!.minX) - currentAdX
        if remainingScreenWidth > adView.frame.width {
            print("Full add horizontally")
        } else {
            if remainingScreenWidth < 0 {
                print("hidden at right: ")
            } else {
                print("left portion: \(remainingScreenWidth)")
            }
        }
    }

//    if (currentAdY + adView.frame.height) < 0 {
//        print("hidden at top: ")
//    } else if currentAdY < 0 {
//        if scrollViewPos!.minY > 0 {
//            let yWithScreen = scrollViewPos!.minY - offset!.y + adCurrentPos!.minY
//            if screenSize.height - yWithScreen > adView.frame.height {
//                print("bottom portion ", adView.frame.height + currentAdY)
//            } else {
//                print("mid portion ")
//            }
//        } else {
//            print("bottom portion ", adView.frame.height + currentAdY)
//        }
//    } else {
//        let remainingScreenHeight = (screenSize.height - scrollViewPos!.minY) - currentAdY
//        if remainingScreenHeight > adView.frame.height {
//            print("Full add vertically")
//        } else {
//            if remainingScreenHeight < 0 {
//                print("hidden at bottom: ")
//            } else {
//                print("top portion: \(remainingScreenHeight)")
//            }
//        }
//    }
    
    return 0.0
}
