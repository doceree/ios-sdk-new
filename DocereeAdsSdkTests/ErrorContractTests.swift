import XCTest
@testable import DocereeAdsSdk

final class ErrorContractTests: XCTestCase {
    func testPopupActionRawValuesMatchContract() {
        XCTAssertEqual(PopupAction.accept.rawValue, "1")
        XCTAssertEqual(PopupAction.reject.rawValue, "0")
        XCTAssertEqual(PopupAction.close.rawValue, "-1")
    }

    func testDocereeAdRequestErrorExplicitRawValues() {
        XCTAssertEqual(DocereeAdRequestError.adNotFound.rawValue, "Ad not found")
        XCTAssertEqual(DocereeAdRequestError.invalidAppKey.rawValue, "invalidAppKey")
        XCTAssertEqual(DocereeAdRequestError.failedToCreateRequest.rawValue, "failedToCreateRequest")
        XCTAssertEqual(DocereeAdRequestError.nonHTTPResponse.rawValue, "nonHTTPResponse")
        XCTAssertEqual(DocereeAdRequestError.httpUnsuccessful.rawValue, "httpUnsuccessful")
    }

    func testDocereeHTTPTimeouts_beaconShorterThanInteractive() {
        XCTAssertLessThanOrEqual(DocereeHTTPTimeouts.beaconRequest, DocereeHTTPTimeouts.interactiveRequest)
        XCTAssertGreaterThan(DocereeHTTPTimeouts.beaconRequest, 0)
    }

    func testHcpRequestErrorRawValues() {
        XCTAssertEqual(HcpRequestError.apiFailed.rawValue, "Api Failed")
        XCTAssertEqual(HcpRequestError.parsingError.rawValue, "Parsing Error")
        XCTAssertEqual(HcpRequestError.noScriptFound.rawValue, "No script found")
    }
}
