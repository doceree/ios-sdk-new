import XCTest
@testable import DocereeAdsSdk

final class AdViewedURLPopulatorTests: XCTestCase {
    private let base =
        "https://qa-ad-test.doceree.com/drs/nEvent?impressionId=imp-1&eType=2&viewedPercentage={{VIEWED_PERCENTAGE}}&viewedTime={{VIEWED_TIME}}&eventClientTime={{EVENT_CLIENT_TIME}}&_std"

    func testKeepsEType2ForViewed() {
        let url = AdViewedURLPopulator.populate(
            url: base,
            viewedTime: 1,
            viewedPercentage: 50,
            standard: "mrc",
            adViewed: true,
            eventClientTime: "123"
        )

        XCTAssertTrue(url.contains("eType=2"))
        XCTAssertFalse(url.contains("eType=5"))
        XCTAssertTrue(url.contains("viewedTime=1"))
        XCTAssertTrue(url.contains("viewedPercentage=50"))
        XCTAssertTrue(url.contains("eventClientTime=123"))
        XCTAssertTrue(url.contains("mrc"))
    }

    func testReplacesEType2With5ForEngagement() {
        let url = AdViewedURLPopulator.populate(
            url: base,
            viewedTime: 5,
            viewedPercentage: 50,
            standard: "mrc",
            adViewed: false,
            eventClientTime: "456"
        )

        XCTAssertTrue(url.contains("eType=5"))
        XCTAssertFalse(url.contains("eType=2"))
    }

    func testDefaultsToEngagementWhenAdViewedFalse() {
        let url = AdViewedURLPopulator.populate(
            url: base,
            viewedTime: 2,
            viewedPercentage: 50,
            standard: "custom",
            adViewed: false
        )

        XCTAssertTrue(url.contains("eType=5"))
        XCTAssertTrue(url.contains("custom"))
    }

    func testEventTypeMapping() {
        XCTAssertEqual(AdViewedURLPopulator.eventType(from: true), 2)
        XCTAssertEqual(AdViewedURLPopulator.eventType(from: false), 5)
    }
}
