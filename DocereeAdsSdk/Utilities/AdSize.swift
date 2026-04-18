
import Foundation
import UIKit

public protocol AdSize {
    var height: CGFloat { set get }
    var width: CGFloat {set get}
    func getAdSize() -> CGSize
    func getAdSizeName() -> String
}

// 320 x 50
struct Banner: AdSize {
    var width: CGFloat
    var height: CGFloat

    init(width: CGFloat = 320, height: CGFloat = 50) {
        self.width = width
        self.height = height
    }

    func getAdSize() -> CGSize {
        return CGSize(width: width, height: height)
    }

    func getAdSizeName() -> String {
        return "BANNER"
    }
}


// 468 x 60
struct FullBanner: AdSize {
    var width: CGFloat
    var height: CGFloat

    init(width: CGFloat = 468, height: CGFloat = 60) {
        self.width = width
        self.height = height
    }

    func getAdSize() -> CGSize {
        return CGSize(width: width, height: height)
    }
    
    func getAdSizeName() -> String {
        return "FULLBANNER"
    }
}

// 300 x 250
struct MediumRectangle : AdSize {
    var width: CGFloat
    var height: CGFloat

    init(width: CGFloat = 300, height: CGFloat = 250) {
        self.width = width
        self.height = height
    }

    func getAdSize() -> CGSize {
        return CGSize(width: width, height: height)
    }
    
    func getAdSizeName() -> String {
        return "MEDIUMRECTANGLE"
    }
}

// 320 x 100
struct LargeBanner: AdSize {
    var width: CGFloat
    var height: CGFloat

    init(width: CGFloat = 320, height: CGFloat = 100) {
        self.width = width
        self.height = height
    }

    func getAdSize() -> CGSize {
        return CGSize(width: width, height: height)
    }
    
    func getAdSizeName() -> String {
        return "LARGEBANNER"
    }
}

// 728 x 90
struct LeaderBoard: AdSize {
    var width: CGFloat
    var height: CGFloat

    init(width: CGFloat = 728, height: CGFloat = 90) {
        self.width = width
        self.height = height
    }

    func getAdSize() -> CGSize {
        return CGSize(width: width, height: height)
    }
    
    func getAdSizeName() -> String {
        return "LEADERBOARD"
    }
}

// 300 x 50
struct SmallBanner: AdSize {
    var width: CGFloat
    var height: CGFloat

    init(width: CGFloat = 300, height: CGFloat = 50) {
        self.width = width
        self.height = height
    }

    func getAdSize() -> CGSize {
        return CGSize(width: width, height: height)
    }
    
    func getAdSizeName() -> String {
        return "SMALLBANNER"
    }
}

// Invalid Size
struct Invalid: AdSize {
    var width: CGFloat
    var height: CGFloat

    init(width: CGFloat = 0, height: CGFloat = 0) {
        self.width = width
        self.height = height
    }

    func getAdSize() -> CGSize {
        return .zero
    }
    
    func getAdSizeName() -> String {
        return "INVALID"
    }
}

// Get Add Size
func getAddSize(adSize: AdSize) -> AdSize {
    if adSize is Banner {
        return Banner()
    } else if adSize is FullBanner {
        return FullBanner()
    } else if adSize is MediumRectangle {
        return MediumRectangle()
    } else if adSize is LargeBanner {
        return LargeBanner()
    } else if adSize is LeaderBoard {
        return LeaderBoard()
    } else if adSize is SmallBanner {
        return SmallBanner()
    } else {
        return Banner()
    }
}
