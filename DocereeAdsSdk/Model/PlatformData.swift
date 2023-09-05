

// MARK: - PlatformData
struct PlatformData: Codable {
    let nm: String
    let em: String
    let sp: String
    let og: String
    let hc: String
    let rx: [String]
    let dx: [String]
    let gd: String
    let ag: String
    let wl: String
    let mo: String
}

// MARK: - PartnerData
struct PartnerData: Codable {
    let pn: String
    let nm: String
    let em: String
    let sp: String
    let og: String
    let hc: String
    let gd: String
    let ag: String
    let wl: String
    let mo: String
}

func getPlatformData(rxCodes: [String]?, dxCodes: [String]?) -> String {
    guard let loggedInUser = DocereeMobileAds.shared().getProfile() else {
        return ""
    }

    let name = Hcp.HcpBuilder().getName()

    let pd = PlatformData(nm: name, em: loggedInUser.email ?? "", sp: loggedInUser.specialization ?? "", og: loggedInUser.organisation ?? "", hc: loggedInUser.mciRegistrationNumber ?? "", rx: rxCodes ?? [], dx: dxCodes ?? [], gd: loggedInUser.gender ?? "", ag: "", wl: loggedInUser.city ?? "", mo: loggedInUser.mobile ?? "")
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(pd)
    let jsonString = String(data: data, encoding: .utf8)!
    let toBase64 = jsonString.toBase64()
    return toBase64!
}

func getParnerData() -> String {
    guard let loggedInUser = DocereeMobileAds.shared().getProfile() else {
        return ""
    }

    let name = Hcp.HcpBuilder().getName()

    let pd = PartnerData(pn: "Partner ID", nm: name, em: loggedInUser.email ?? "", sp: loggedInUser.specialization ?? "", og: loggedInUser.organisation ?? "", hc: loggedInUser.mciRegistrationNumber ?? "", gd: loggedInUser.gender ?? "", ag: "", wl: loggedInUser.city ?? "", mo: loggedInUser.mobile ?? "")
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(pd)
    let jsonString = String(data: data, encoding: .utf8)!
    let toBase64 = jsonString.toBase64()
    return toBase64!
}
