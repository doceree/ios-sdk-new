
import Foundation

internal struct AdResponse: Codable {
    let sourceURL: String?
    let CBID: String?
    let DIVID: String?
    let ctaLink: String?
    let newPlatformUid: String?
    let height: String?
    let width: String?
    let platformUID: String?
    let debugMessage: String?
    let version: String?
    let maxAge: Int?
    let passbackTag: String?
    let impressionLink: String?
    let IntegrationType: String?
    let creativeType: String?
    let errMessage: String?
    let viewLink: String?
    let minViewPercentage: Int?
    let minViewTime: Int?
    
    enum Platformuid: String{
        case platformuid = "platformuid"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        self.CBID = try container.decodeIfPresent(String.self, forKey: .CBID)
        self.DIVID = try container.decodeIfPresent(String.self, forKey: .DIVID)
        self.ctaLink = try container.decodeIfPresent(String.self, forKey: .ctaLink)
        self.newPlatformUid = try container.decodeIfPresent(String.self, forKey: .newPlatformUid)
        self.height = try container.decodeIfPresent(String.self, forKey: .height)
        self.width = try container.decodeIfPresent(String.self, forKey: .width)
        self.platformUID = try container.decodeIfPresent(String.self, forKey: .platformUID)
        self.debugMessage = try container.decodeIfPresent(String.self, forKey: .debugMessage)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        self.maxAge = try container.decodeIfPresent(Int.self, forKey: .maxAge)
        self.passbackTag = try container.decodeIfPresent(String.self, forKey: .passbackTag)
        self.impressionLink = try container.decodeIfPresent(String.self, forKey: .impressionLink)
        self.IntegrationType = try container.decodeIfPresent(String.self, forKey: .IntegrationType)
        self.creativeType = try container.decodeIfPresent(String.self, forKey: .creativeType)
        self.errMessage = try container.decodeIfPresent(String.self, forKey: .errMessage)
        self.viewLink = try container.decodeIfPresent(String.self, forKey: .viewLink)
        self.minViewPercentage = try container.decodeIfPresent(Int.self, forKey: .minViewPercentage)
        self.minViewTime = try container.decodeIfPresent(Int.self, forKey: .minViewTime)
    }
    
    internal func isAdRichMedia() -> Bool{
        let givenType = self.creativeType
        let html = "html"
        let custom_html = "custom_html"
        let text_ad = "text_ad"
        return compareIfSame(presentValue: givenType!, expectedValue: html) || compareIfSame(presentValue: givenType!, expectedValue: custom_html) || compareIfSame(presentValue: givenType!, expectedValue: text_ad)
    }
    internal func standard() -> String {
        if minViewTime == 0 {
            return "mrc"
        } else {
            return "custom"
        }
        
    }
    func compareIfSame(presentValue: String, expectedValue: String) -> Bool {
        return presentValue.caseInsensitiveCompare(expectedValue) == ComparisonResult.orderedSame
    }

}


struct Results {
    var data: Data?
    var response: HTTPURLResponse?
    var error: Error?
    
    init(withData data: Data?, response: HTTPURLResponse?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
}
