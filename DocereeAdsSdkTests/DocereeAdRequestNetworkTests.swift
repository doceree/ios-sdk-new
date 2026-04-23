import XCTest
@testable import DocereeAdsSdk

private final class MockURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var _handler: ((URLRequest) throws -> (URLResponse, Data))?

    static func setHandler(_ handler: @escaping (URLRequest) throws -> (URLResponse, Data)) {
        lock.lock()
        _handler = handler
        lock.unlock()
    }

    static func clearHandler() {
        lock.lock()
        _handler = nil
        lock.unlock()
    }

    private static func handlerForRequest() -> ((URLRequest) throws -> (URLResponse, Data))? {
        lock.lock()
        defer { lock.unlock() }
        return _handler
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handlerForRequest() else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if !data.isEmpty {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class AtomicCallCount {
    private let lock = NSLock()
    private var value = 0
    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

final class DocereeAdRequestNetworkTests: XCTestCase {

    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
    }

    override func tearDown() {
        MockURLProtocol.clearHandler()
        session = nil
        super.tearDown()
    }

    private func makeAdProbeRequest() -> URLRequest {
        let url = URL(string: "https://doceree-ad-test.invalid/drs/quest")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        return request
    }

    func testPerformAdNetworkFetchWithRetries_nonHTTPResponse_mapsToError() async {
        MockURLProtocol.setHandler { request in
            let plain = URLResponse(
                url: request.url!,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (plain, Data())
        }
        let client = DocereeAdRequest(urlSession: session)
        do {
            _ = try await client.performAdNetworkFetchWithRetries(makeAdProbeRequest())
            XCTFail("Expected error")
        } catch DocereeAdRequestError.nonHTTPResponse {
            return
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPerformAdNetworkFetchWithRetries_retries503ThenSucceeds() async throws {
        let calls = AtomicCallCount()
        MockURLProtocol.setHandler { request in
            let n = calls.increment()
            if n < 3 {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 503,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, Data("busy".utf8))
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        let client = DocereeAdRequest(urlSession: session)
        let (data, http) = try await client.performAdNetworkFetchWithRetries(makeAdProbeRequest())
        XCTAssertTrue((200...299).contains(http.statusCode))
        XCTAssertEqual(calls.count, 3)
        XCTAssertEqual(data.count, 0)
    }

    func testPerformAdNetworkFetchWithRetries_doesNotRetry404() async {
        let calls = AtomicCallCount()
        MockURLProtocol.setHandler { request in
            _ = calls.increment()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("nf".utf8))
        }
        let client = DocereeAdRequest(urlSession: session)
        do {
            _ = try await client.performAdNetworkFetchWithRetries(makeAdProbeRequest())
            XCTFail("Expected error")
        } catch DocereeAdRequestError.httpUnsuccessful {
            XCTAssertEqual(calls.count, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
