import Foundation

/// Publisher-attested consent supplied by the main app at login.
public struct PublisherAttestedConsent: Equatable {
    public let consentBasis: String?
    public let mechanism: String?
    public let grantedAt: String?
    public let expiresAt: String?
    public let consentReferenceId: String?

    internal init(
        consentBasis: String? = nil,
        mechanism: String? = nil,
        grantedAt: String? = nil,
        expiresAt: String? = nil,
        consentReferenceId: String? = nil
    ) {
        self.consentBasis = consentBasis
        self.mechanism = mechanism
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
        self.consentReferenceId = consentReferenceId
    }

    func cnsPayload() -> [String: Any] {
        var payload: [String: Any] = [:]
        addNonEmpty(consentBasis, forKey: .consentBasis, into: &payload)
        addNonEmpty(mechanism, forKey: .mechanism, into: &payload)
        addNonEmpty(grantedAt, forKey: .grantedAt, into: &payload)
        addNonEmpty(expiresAt, forKey: .expiresAt, into: &payload)
        addNonEmpty(consentReferenceId, forKey: .consentReferenceId, into: &payload)
        return payload
    }

    var isEmpty: Bool {
        cnsPayload().isEmpty
    }

    private func addNonEmpty(_ value: String?, forKey key: PublisherAttestedConsentKey, into payload: inout [String: Any]) {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return }
        payload[key.rawValue] = value
    }
}

/// Builds publisher-attested consent for profile builders. Maps to ad-request `cns` keys internally.
public final class PublisherAttestedConsentBuilder {

    private var consentBasis: String?
    private var mechanism: String?
    private var grantedAt: String?
    private var expiresAt: String?
    private var consentReferenceId: String?

    public init() {}

    public func setConsentBasis(_ consentBasis: String?) -> PublisherAttestedConsentBuilder {
        self.consentBasis = consentBasis
        return self
    }

    public func setMechanism(_ mechanism: String?) -> PublisherAttestedConsentBuilder {
        self.mechanism = mechanism
        return self
    }

    public func setGrantedAt(_ grantedAt: String?) -> PublisherAttestedConsentBuilder {
        self.grantedAt = grantedAt
        return self
    }

    public func setExpiresAt(_ expiresAt: String?) -> PublisherAttestedConsentBuilder {
        self.expiresAt = expiresAt
        return self
    }

    public func setConsentReferenceId(_ consentReferenceId: String?) -> PublisherAttestedConsentBuilder {
        self.consentReferenceId = consentReferenceId
        return self
    }

    public func build() -> PublisherAttestedConsent {
        PublisherAttestedConsent(
            consentBasis: consentBasis,
            mechanism: mechanism,
            grantedAt: grantedAt,
            expiresAt: expiresAt,
            consentReferenceId: consentReferenceId
        )
    }
}

enum PublisherAttestedConsentKey: String {
    case consentBasis = "bas"
    case mechanism = "mech"
    case grantedAt = "gat"
    case expiresAt = "eat"
    case consentReferenceId = "crid"
}
