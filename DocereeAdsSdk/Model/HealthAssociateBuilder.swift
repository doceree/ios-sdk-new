import Foundation

/// Builds a Health Associate profile for `DocereeMobileAds.login(with:)`.
public final class HealthAssociateBuilder: DocereeProfileBuilding {

    private var storage = HcpProfileBuilderStorage()

    public init() {}

    public func setFirstName(_ firstName: String?) -> HealthAssociateBuilder {
        storage.firstName = firstName
        return self
    }

    public func setLastName(_ lastName: String?) -> HealthAssociateBuilder {
        storage.lastName = lastName
        return self
    }

    public func setEmail(_ email: String?) -> HealthAssociateBuilder {
        storage.email = email
        return self
    }

    public func setHashedEmail(_ hashedEmail: String?) -> HealthAssociateBuilder {
        storage.hashedEmail = hashedEmail
        return self
    }

    public func setMobile(_ mobile: String?) -> HealthAssociateBuilder {
        storage.mobile = mobile
        return self
    }

    public func setHashedMobile(_ hashedMobile: String?) -> HealthAssociateBuilder {
        storage.hashedMobile = hashedMobile
        return self
    }

    public func setDateOfBirth(_ dateOfBirth: String?) -> HealthAssociateBuilder {
        storage.dateOfBirth = dateOfBirth
        return self
    }

    public func setGender(_ gender: String?) -> HealthAssociateBuilder {
        storage.gender = gender
        return self
    }

    public func setCity(_ city: String?) -> HealthAssociateBuilder {
        storage.city = city
        return self
    }

    public func setState(_ state: String?) -> HealthAssociateBuilder {
        storage.state = state
        return self
    }

    public func setCountry(_ country: String?) -> HealthAssociateBuilder {
        storage.country = country
        return self
    }

    public func setZipCode(_ zipCode: String?) -> HealthAssociateBuilder {
        storage.zipCode = zipCode
        return self
    }

    public func setAssociateId(_ associateId: String?) -> HealthAssociateBuilder {
        storage.associateId = associateId
        return self
    }

    public func setHashedAssociateId(_ hashedAssociateId: String?) -> HealthAssociateBuilder {
        storage.hashedAssociateId = hashedAssociateId
        return self
    }

    public func setAssociateRole(_ associateRole: String?) -> HealthAssociateBuilder {
        storage.associateRole = associateRole
        return self
    }

    public func setDepartment(_ department: String?) -> HealthAssociateBuilder {
        storage.department = department
        return self
    }

    public func setClinicalInfluenceTier(_ clinicalInfluenceTier: Int?) -> HealthAssociateBuilder {
        storage.clinicalInfluenceTier = clinicalInfluenceTier
        return self
    }

    public func setConsent(_ consent: PublisherAttestedConsent?) -> HealthAssociateBuilder {
        storage.publisherAttestedConsent = consent
        return self
    }

    public func build() -> Hcp {
        storage.build(defaultRole: .hcp)
    }
}
