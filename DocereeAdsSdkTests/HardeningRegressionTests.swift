import XCTest
@testable import DocereeAdsSdk

final class HardeningRegressionTests: XCTestCase {

    func testMakeAppConfigurationURL_matchesManualConstructionForEachEnvironment() {
        for env in [EnvironmentType.Dev, .Local, .Qa, .Prod] {
            let host = getIdentityHost(type: env)
            let expected = URL(string: "https://\(host)\(getPath(methodName: Methods.AppConfig, type: env))")
            XCTAssertEqual(
                ConfigurationService.makeAppConfigurationURL(identityHost: host, environment: env),
                expected,
                "URL mismatch for environment \(env)"
            )
            XCTAssertTrue(
                ConfigurationService.makeAppConfigurationURL(identityHost: host, environment: env)?.absoluteString.contains("/dop/settings") == true
            )
        }
    }

    func testDecodeAppConfiguration_throwsOnInvalidJSON() {
        let data = Data("{}".utf8)
        XCTAssertThrowsError(try ConfigurationService.decodeAppConfiguration(from: data))
    }

    func testAppConfigurationServiceError_localizedDescriptionIncludesResponsePreview() {
        let err = AppConfigurationServiceError.decodingFailed(
            underlying: NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "inner"]),
            responseBodyPreview: "{\"not\":\"AppConfiguration\"}"
        )
        let description = err.localizedDescription
        XCTAssertTrue(description.contains("inner"), description)
        XCTAssertTrue(description.contains("{\"not\":\"AppConfiguration\"}"), description)
    }

    func testAppConfigurationServiceError_httpStatusIncludesPreview() {
        let err = AppConfigurationServiceError.httpStatusNotSuccess(statusCode: 503, responseBodyPreview: "retry")
        XCTAssertTrue(err.localizedDescription.contains("503"), err.localizedDescription)
        XCTAssertTrue(err.localizedDescription.contains("retry"), err.localizedDescription)
    }

    func testAppConfigurationServiceError_invalidHTTPResponseDescription() {
        let err = AppConfigurationServiceError.invalidHTTPResponse
        XCTAssertFalse(err.localizedDescription.isEmpty)
    }

    func testDecodeAppConfiguration_succeedsOnMinimalValidPayload() throws {
        let json = """
        {"timestamp":"t","code":1,"status":"s","message":"m","data":{"hcpValidation":true,"ketchConsent":false,"appId":"aid","platformId":null}}
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try ConfigurationService.decodeAppConfiguration(from: data)
        XCTAssertEqual(decoded.data.appId, "aid")
        XCTAssertTrue(decoded.data.hcpValidation)
        XCTAssertFalse(decoded.data.ketchConsent)
    }

    func testGetPlatformData_withoutProfile_returnsEmptyString() {
        XCTAssertEqual(getPlatformData(rxCodes: nil, dxCodes: nil), "")
    }

    func testGetPartnerData_withoutProfile_returnsEmptyString() {
        XCTAssertEqual(getParnerData(), "")
    }

    func testPlatformData_encodesToNonEmptyJSON() throws {
        let pd = PlatformData(
            nm: "n",
            em: "e",
            sp: "s",
            og: "o",
            hc: "h",
            rx: ["rx1"],
            dx: ["dx1"],
            gd: "g",
            ag: "",
            wl: "w",
            mo: "m"
        )
        let data = try JSONEncoder().encode(pd)
        XCTAssertFalse(data.isEmpty)
        let roundTrip = try JSONDecoder().decode(PlatformData.self, from: data)
        XCTAssertEqual(roundTrip.nm, "n")
        XCTAssertEqual(roundTrip.rx, ["rx1"])
    }
}
