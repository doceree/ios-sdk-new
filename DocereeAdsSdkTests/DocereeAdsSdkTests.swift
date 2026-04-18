//
//  DocereeAdsSdkTests.swift
//  DocereeAdsSdkTests
//

import XCTest
@testable import DocereeAdsSdk

final class DocereeAdsSdkTests: XCTestCase {

    // MARK: - PopupAction

    func testPopupActionRawValuesMatchContract() {
        XCTAssertEqual(PopupAction.accept.rawValue, "1")
        XCTAssertEqual(PopupAction.reject.rawValue, "0")
        XCTAssertEqual(PopupAction.close.rawValue, "-1")
    }

    // MARK: - DocereeAdRequestError & HcpRequestError

    func testDocereeAdRequestErrorExplicitRawValues() {
        XCTAssertEqual(DocereeAdRequestError.adNotFound.rawValue, "Ad not found")
        XCTAssertEqual(DocereeAdRequestError.invalidAppKey.rawValue, "invalidAppKey")
        XCTAssertEqual(DocereeAdRequestError.failedToCreateRequest.rawValue, "failedToCreateRequest")
    }

    func testHcpRequestErrorRawValues() {
        XCTAssertEqual(HcpRequestError.apiFailed.rawValue, "Api Failed")
        XCTAssertEqual(HcpRequestError.parsingError.rawValue, "Parsing Error")
        XCTAssertEqual(HcpRequestError.noScriptFound.rawValue, "No script found")
    }

    // MARK: - AdSize

    func testBannerDefaultSizeAndName() {
        let banner = Banner()
        XCTAssertEqual(banner.width, 320)
        XCTAssertEqual(banner.height, 50)
        XCTAssertEqual(banner.getAdSize(), CGSize(width: 320, height: 50))
        XCTAssertEqual(banner.getAdSizeName(), "BANNER")
    }

    func testMediumRectangleDefaultSizeAndName() {
        let mrect = MediumRectangle()
        XCTAssertEqual(mrect.getAdSize(), CGSize(width: 300, height: 250))
        XCTAssertEqual(mrect.getAdSizeName(), "MEDIUMRECTANGLE")
    }

    func testLeaderBoardDefaultSizeAndName() {
        let lb = LeaderBoard()
        XCTAssertEqual(lb.getAdSize(), CGSize(width: 728, height: 90))
        XCTAssertEqual(lb.getAdSizeName(), "LEADERBOARD")
    }

    func testInvalidAdSizeAlwaysZeroAndNameInvalid() {
        let invalid = Invalid()
        XCTAssertEqual(invalid.getAdSize(), .zero)
        XCTAssertEqual(invalid.getAdSizeName(), "INVALID")
    }

    func testGetAddSizeReturnsFreshInstancesWithDefaults() {
        XCTAssertEqual(getAddSize(adSize: Banner()).getAdSize(), CGSize(width: 320, height: 50))
        XCTAssertEqual(getAddSize(adSize: FullBanner()).getAdSize(), CGSize(width: 468, height: 60))
        XCTAssertEqual(getAddSize(adSize: MediumRectangle()).getAdSize(), CGSize(width: 300, height: 250))
        XCTAssertEqual(getAddSize(adSize: LargeBanner()).getAdSize(), CGSize(width: 320, height: 100))
        XCTAssertEqual(getAddSize(adSize: LeaderBoard()).getAdSize(), CGSize(width: 728, height: 90))
        XCTAssertEqual(getAddSize(adSize: SmallBanner()).getAdSize(), CGSize(width: 300, height: 50))
    }

    func testGetAddSizeFallsBackToBannerForUnknownConcreteType() {
        let result = getAddSize(adSize: Invalid(width: 99, height: 99))
        XCTAssertTrue(result is Banner)
        XCTAssertEqual(result.getAdSize(), CGSize(width: 320, height: 50))
        XCTAssertEqual(result.getAdSizeName(), "BANNER")
    }

    // MARK: - PatientBuilder

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
