

// MARK: - adBlockRequest
struct AdBlockRequest: Codable {
    let publisherACSID: String
    let advertiserCampID: String
    let blockLevel: String
    let platformUid: String
}
