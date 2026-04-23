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

final class ConfigurationServiceNetworkTests: XCTestCase {

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

    private func makeRequest() -> URLRequest {
        let url = URL(string: "https://doceree-config-test.invalid/app-config")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        return request
    }

    func testExecuteAppConfigurationRequest_nonHTTPResponse_throwsInvalidHTTPResponse() async {
        MockURLProtocol.setHandler { request in
            let plain = URLResponse(
                url: request.url!,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (plain, Data())
        }
        let service = ConfigurationService(urlSession: session)
        do {
            _ = try await service.executeAppConfigurationRequest(makeRequest())
            XCTFail("Expected error")
        } catch let error as AppConfigurationServiceError {
            if case .invalidHTTPResponse = error { return }
            XCTFail("Wrong case: \(error)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteAppConfigurationRequest_http500_throwsWithPreview() async {
        MockURLProtocol.setHandler { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("server-boom".utf8))
        }
        let service = ConfigurationService(urlSession: session)
        do {
            _ = try await service.executeAppConfigurationRequest(makeRequest())
            XCTFail("Expected error")
        } catch let error as AppConfigurationServiceError {
            if case .httpStatusNotSuccess(let code, let preview) = error {
                XCTAssertEqual(code, 500)
                XCTAssertEqual(preview, "server-boom")
            } else {
                XCTFail("Wrong case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteAppConfigurationRequest_http200InvalidJSON_throwsDecodingFailed() async {
        MockURLProtocol.setHandler { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{}".utf8))
        }
        let service = ConfigurationService(urlSession: session)
        do {
            _ = try await service.executeAppConfigurationRequest(makeRequest())
            XCTFail("Expected error")
        } catch let error as AppConfigurationServiceError {
            if case .decodingFailed(_, let preview) = error {
                XCTAssertEqual(preview, "{}")
            } else {
                XCTFail("Wrong case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteAppConfigurationRequest_http200ValidJSON_succeeds() async throws {
        let json = """
        {"timestamp":"t","code":1,"status":"s","message":"m","data":{"hcpValidation":true,"ketchConsent":false,"appId":"aid","platformId":null}}
        """
        MockURLProtocol.setHandler { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(json.utf8))
        }
        let service = ConfigurationService(urlSession: session)
        let decoded = try await service.executeAppConfigurationRequest(makeRequest())
        XCTAssertEqual(decoded.data.appId, "aid")
    }

    func testExecuteAppConfigurationRequest_retries5xxThenSucceeds() async throws {
        let json = """
        {"timestamp":"t","code":1,"status":"s","message":"m","data":{"hcpValidation":true,"ketchConsent":false,"appId":"retry-ok","platformId":null}}
        """
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
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(json.utf8))
        }
        let service = ConfigurationService(urlSession: session)
        let decoded = try await service.executeAppConfigurationRequest(makeRequest())
        XCTAssertEqual(decoded.data.appId, "retry-ok")
        XCTAssertEqual(calls.count, 3)
    }

    func testExecuteAppConfigurationRequest_doesNotRetry4xx() async {
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
        let service = ConfigurationService(urlSession: session)
        do {
            _ = try await service.executeAppConfigurationRequest(makeRequest())
            XCTFail("Expected error")
        } catch let error as AppConfigurationServiceError {
            guard case .httpStatusNotSuccess(let code, _) = error else {
                XCTFail("Wrong case \(error)")
                return
            }
            XCTAssertEqual(code, 404)
        } catch {
            XCTFail("Unexpected \(error)")
        }
        XCTAssertEqual(calls.count, 1)
    }
}
