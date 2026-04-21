import XCTest
@testable import DocereeAdsSdk

final class PatientBuilderTests: XCTestCase {
    func testPatientToJsonOmitsEmptyDefaultBuilder() {
        let json = PatientBuilder().build().toJson()
        XCTAssertTrue(json.isEmpty, "All-default patient fields should be filtered out")
    }

    func testPatientToJsonIncludesAgeUnderPatientDataKey() {
        let json = PatientBuilder().add(key: "age", value: "42").build().toJson()
        XCTAssertEqual(json["ag"] as? String, "42")
    }

    func testPatientToJsonIncludesSessionIdUnderPatientDataKey() {
        let json = PatientBuilder().add(key: "sessionId", value: "sess-1").build().toJson()
        XCTAssertEqual(json["sid"] as? String, "sess-1")
    }
}
