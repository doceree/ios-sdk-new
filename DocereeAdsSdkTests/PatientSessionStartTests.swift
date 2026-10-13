import XCTest
@testable import DocereeAdsSdk

final class PatientSessionStartTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PatientSession.sessionId = nil
        StorageManager.shared.clearAllAttributeAndSessionData()
    }

    override func tearDown() {
        PatientSession.sessionId = nil
        StorageManager.shared.clearAllAttributeAndSessionData()
        super.tearDown()
    }

    func testStartSessionEndsPersistedSessionWhenMemoryIsEmpty() async {
        await StorageManager.shared.saveItem(forKey: "sessionId", value: "orphan-session-id")
        PatientSession.sessionId = nil

        let session = PatientSession()
        await session.startSession()

        XCTAssertNil(StorageManager.shared.getItem(forKey: "sessionId"))
        XCTAssertNotNil(PatientSession.sessionId)
        XCTAssertNotEqual(PatientSession.sessionId, "orphan-session-id")
    }
}
