import Foundation

/// Deprecated — use `DocereeConsent` and `DocereeMobileAds.shared().setConsent(_:)` instead.
@available(*, deprecated, message: "Use DocereeConsent and DocereeMobileAds.shared().setConsent(_:)")
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

    func toDocereeConsent() -> DocereeConsent {
        DocereeConsent(
            consentBasis: consentBasis,
            mechanism: mechanism,
            grantedAt: grantedAt,
            expiresAt: expiresAt,
            consentReferenceId: consentReferenceId
        )
    }
}

/// Deprecated — use `DocereeConsentBuilder` instead.
@available(*, deprecated, message: "Use DocereeConsentBuilder")
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
