import XCTest
@testable import DocereeAdsSdk

final class HardeningRegressionTests: XCTestCase {

    func testMakeAppConfigurationURL_matchesManualConstructionForEachEnvironment() {
        for env in [EnvironmentType.Dev, .Local, .Qa, .Prod] {
            let host = getIdentityHost(type: env)
            let expected = URL(string: "https://\(host)\(getPath(methodName: Methods.AppConfig))")
            XCTAssertEqual(
                ConfigurationService.makeAppConfigurationURL(identityHost: host),
                expected,
                "URL mismatch for environment \(env)"
            )
            XCTAssertTrue(
                ConfigurationService.makeAppConfigurationURL(identityHost: host)?.absoluteString.contains("/dop/settings") == true
            )
        }
    }

    func testDecodeAppConfiguration_throwsOnInvalidJSON() {
        let data = Data("{}".utf8)
        XCTAssertThrowsError(try ConfigurationService.decodeAppConfiguration(from: data))
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
