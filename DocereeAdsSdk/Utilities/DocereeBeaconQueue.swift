import Foundation

/// Offline queue for measurement beacons, intake, session pings, and ad-block reports (React Native `BeaconQueue` parity).
enum DocereeBeaconQueue {
    static let storageKey = "docereeBeaconQueue"

    private static let maxQueue = 100
    private static let maxAgeMs: Int64 = 24 * 60 * 60 * 1000
    private static let sessionMaxAgeMs: Int64 = 30 * 60 * 1000
    private static let maxAttempts = 5
    private static let backoffBaseMs: Int64 = 2000
    private static let backoffMaxMs: Int64 = 60_000

    enum Kind: String, Codable {
        case impression
        case viewability
        case intake
        case session
        case adblock
    }

    struct QueuedItem: Codable, Equatable {
        let id: String
        let kind: Kind
        var url: String
        var method: String
        var body: String?
        var headers: [String: String]?
        var sessionId: String?
        let createdAt: Int64
        var attempts: Int
        var nextAttemptAt: Int64?
    }

    private static let queueLock = NSLock()
    private static var flushInFlight: Task<Void, Never>?

    private static let flushPriority: [Kind: Int] = [
        .session: 0,
        .impression: 1,
        .viewability: 2,
        .intake: 3,
        .adblock: 4
    ]

    static func backoffDelayMs(attempts: Int) -> Int64 {
        let exponent = max(0, attempts - 1)
        let scaled = backoffBaseMs * Int64(1 << min(exponent, 10))
        return min(backoffMaxMs, scaled)
    }

    static func normalizeMeasurementURL(_ url: String) -> String {
        guard var components = URLComponents(string: url) else {
            return url
                .replacingOccurrences(
                    of: #"([?&][^=]*?(?:time|viewed|percent|timestamp|ts|client)[^=]*=)[^&]*"#,
                    with: "$1*",
                    options: .regularExpression
                )
                .replacingOccurrences(of: #"\d{10,16}"#, with: "*", options: .regularExpression)
        }

        if let queryItems = components.queryItems {
            var normalized: [URLQueryItem] = []
            for item in queryItems {
                if item.name.range(of: #"(?i)(time|viewed|percent|timestamp|ts|client)"#, options: .regularExpression) != nil {
                    normalized.append(URLQueryItem(name: item.name, value: "*"))
                } else {
                    normalized.append(item)
                }
            }
            components.queryItems = normalized
        }

        var path = components.path
        path = path.replacingOccurrences(of: #"/\d{6,}"#, with: "/*", options: .regularExpression)
        components.path = path

        guard let rebuilt = components.url?.absoluteString else { return url }
        return rebuilt
    }

    private static func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private static func maxAgeMs(for kind: Kind) -> Int64 {
        kind == .session ? sessionMaxAgeMs : maxAgeMs
    }

    private static func prune(_ queue: [QueuedItem], now: Int64 = nowMs()) -> [QueuedItem] {
        queue
            .filter { now - $0.createdAt <= maxAgeMs(for: $0.kind) && $0.attempts < maxAttempts }
            .suffix(maxQueue)
            .map { $0 }
    }

    private static func dedupeKey(for item: QueuedItem) -> String {
        let method = item.method.uppercased()
        if item.kind == .impression || item.kind == .viewability {
            return "\(item.kind.rawValue)|\(method)|\(normalizeMeasurementURL(item.url))"
        }
        return "\(item.kind.rawValue)|\(method)|\(item.url)|\(item.body ?? "")"
    }

    private static func loadQueueUnlocked() -> [QueuedItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        do {
            return try JSONDecoder().decode([QueuedItem].self, from: data)
        } catch {
            return []
        }
    }

    private static func saveQueueUnlocked(_ queue: [QueuedItem]) {
        let pruned = prune(queue)
        if pruned.isEmpty {
            UserDefaults.standard.removeObject(forKey: storageKey)
            return
        }
        if let data = try? JSONEncoder().encode(pruned) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private static func withQueueLock<T>(_ work: () throws -> T) rethrows -> T {
        queueLock.lock()
        defer { queueLock.unlock() }
        return try work()
    }

    static func loadQueue() -> [QueuedItem] {
        withQueueLock { prune(loadQueueUnlocked()) }
    }

    static func clearQueue() {
        withQueueLock {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
    }

    static func enqueueRequest(
        kind: Kind,
        url: String,
        method: String = HTTPMethod.get,
        body: String? = nil,
        headers: [String: String]? = nil,
        sessionId: String? = nil
    ) {
        guard !url.isEmpty else { return }
        withQueueLock {
            var queue = prune(loadQueueUnlocked())
            let candidate = QueuedItem(
                id: "",
                kind: kind,
                url: url,
                method: method,
                body: body,
                headers: headers,
                sessionId: sessionId,
                createdAt: nowMs(),
                attempts: 0,
                nextAttemptAt: nil
            )
            let key = dedupeKey(for: candidate)
            if let index = queue.firstIndex(where: { dedupeKey(for: $0) == key }) {
                var existing = queue[index]
                existing.url = url
                existing.method = method
                existing.body = body ?? existing.body
                existing.headers = headers ?? existing.headers
                existing.sessionId = sessionId ?? existing.sessionId
                queue[index] = existing
                saveQueueUnlocked(queue)
                DocereeLog.debug("Request coalesced (\(kind.rawValue))")
                return
            }

            queue.append(
                QueuedItem(
                    id: "\(kind.rawValue)-\(nowMs())-\(UUID().uuidString.prefix(6))",
                    kind: kind,
                    url: url,
                    method: method,
                    body: body,
                    headers: headers,
                    sessionId: sessionId,
                    createdAt: nowMs(),
                    attempts: 0,
                    nextAttemptAt: nil
                )
            )
            saveQueueUnlocked(queue)
            DocereeLog.debug("Request queued (\(kind.rawValue))")
        }
    }

    static func enqueueBeacon(kind: Kind, url: String) {
        enqueueRequest(kind: kind, url: url, method: HTTPMethod.get)
    }

    static func sendBeaconOrEnqueue(kind: Kind, request: URLRequest) {
        Task {
            do {
                try await DocereeURLSessionBeacon.sendWithRetriesOrThrow(
                    for: request,
                    session: .shared,
                    message: kind.rawValue.capitalized
                )
                DocereeLog.debug("\(kind.rawValue) sent")
            } catch {
                DocereeLog.debug("\(kind.rawValue) failed, persisting: \(error.localizedDescription)")
                enqueueFromRequest(kind: kind, request: request)
            }
        }
    }

    static func sendRequestOrEnqueue(
        kind: Kind,
        request: URLRequest,
        sessionId: String? = nil
    ) {
        Task {
            do {
                try await dispatch(liveItem(from: request, kind: kind, sessionId: sessionId))
                DocereeLog.debug("\(kind.rawValue) sent")
            } catch {
                DocereeLog.debug("\(kind.rawValue) failed, persisting: \(error.localizedDescription)")
                enqueueFromRequest(kind: kind, request: request, sessionId: sessionId)
            }
        }
    }

    static func flushQueue() {
        if flushInFlight != nil { return }
        flushInFlight = Task {
            defer { flushInFlight = nil }
            guard await DocereeNetworkReachability.isNetworkAvailable() else {
                DocereeLog.debug("Skipping beacon flush — network unavailable")
                return
            }
            await performFlush()
        }
    }

    private static func performFlush() async {
        let snapshot = withQueueLock { prune(loadQueueUnlocked()) }
            .sorted {
                (flushPriority[$0.kind] ?? 99) < (flushPriority[$1.kind] ?? 99)
            }
        let now = nowMs()
        var remaining: [QueuedItem] = []

        for var item in snapshot {
            if await shouldDropStaleSession(item) {
                DocereeLog.debug("Dropping stale session ping (\(item.sessionId ?? ""))")
                continue
            }
            if now < (item.nextAttemptAt ?? 0) {
                DocereeLog.debug("Deferring \(item.kind.rawValue) retry until backoff elapses (attempt \(item.attempts))")
                remaining.append(item)
                continue
            }
            do {
                try await dispatch(item)
                DocereeLog.debug("Flushed \(item.kind.rawValue)")
            } catch {
                let attempts = item.attempts + 1
                let delay = backoffDelayMs(attempts: attempts)
                item.attempts = attempts
                item.nextAttemptAt = now + delay
                remaining.append(item)
                DocereeLog.debug("\(item.kind.rawValue) flush failed; retry in \(delay)ms (attempt \(attempts))")
            }
        }

        withQueueLock {
            var current = prune(loadQueueUnlocked())
            let snapshotIds = Set(snapshot.map(\.id))
            current.removeAll { snapshotIds.contains($0.id) }
            current.append(contentsOf: remaining)
            saveQueueUnlocked(current)
        }
    }

    private static func liveItem(from request: URLRequest, kind: Kind, sessionId: String? = nil) -> QueuedItem {
        QueuedItem(
            id: "live",
            kind: kind,
            url: request.url?.absoluteString ?? "",
            method: request.httpMethod ?? HTTPMethod.get,
            body: request.httpBody.flatMap { String(data: $0, encoding: .utf8) },
            headers: request.allHTTPHeaderFields,
            sessionId: sessionId,
            createdAt: nowMs(),
            attempts: 0,
            nextAttemptAt: nil
        )
    }

    private static func enqueueFromRequest(kind: Kind, request: URLRequest, sessionId: String? = nil) {
        enqueueRequest(
            kind: kind,
            url: request.url?.absoluteString ?? "",
            method: request.httpMethod ?? HTTPMethod.get,
            body: request.httpBody.flatMap { String(data: $0, encoding: .utf8) },
            headers: request.allHTTPHeaderFields,
            sessionId: sessionId
        )
    }

    private static func dispatch(_ item: QueuedItem) async throws {
        let request = try await buildURLRequest(for: item)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        if item.kind == .intake {
            try HealthcareIntakeClient.applyQueuedIntakeResponseBody(data)
        }
    }

    private static func buildURLRequest(for item: QueuedItem) async throws -> URLRequest {
        guard let url = URL(string: item.url) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = item.method
        request.timeoutInterval = DocereeHTTPTimeouts.beaconRequest
        if item.kind == .session {
            request.allHTTPHeaderFields = try await Header().getHeaders()
        } else {
            request.allHTTPHeaderFields = item.headers
        }
        if item.method.uppercased() == HTTPMethod.post, let body = item.body {
            request.httpBody = Data(body.utf8)
        }
        return request
    }

    private static func sessionStatus(from url: String) -> String? {
        guard let components = URLComponents(string: url),
              let status = components.queryItems?.first(where: { $0.name == "status" })?.value else {
            return nil
        }
        return status
    }

    private static func shouldDropStaleSession(_ item: QueuedItem) async -> Bool {
        guard item.kind == .session else { return false }
        if nowMs() - item.createdAt > sessionMaxAgeMs { return true }
        if sessionStatus(from: item.url) == "1", let queuedSessionId = item.sessionId {
            let localSid = StorageManager.shared.getItem(forKey: "sessionId") ?? ""
            return localSid != queuedSessionId
        }
        return false
    }
}
