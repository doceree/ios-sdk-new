import Foundation

/// Builds a user profile for `DocereeMobileAds.login(with:)`.
public final class UserBuilder: DocereeProfileBuilding {

    private var storage = HcpProfileBuilderStorage()

    public init() {}

    public func setFirstName(_ firstName: String?) -> UserBuilder {
        storage.firstName = firstName
        return self
    }

    public func setLastName(_ lastName: String?) -> UserBuilder {
        storage.lastName = lastName
        return self
    }

    /// Profile sub-type such as `"HCP"` or `"DTC"` (distinct from SDK login role).
    public func setUserType(_ userType: String?) -> UserBuilder {
        storage.userType = userType
        return self
    }

    public func setSpecialization(_ specialization: String?) -> UserBuilder {
        storage.specialization = specialization
        return self
    }

    public func setOrganisation(_ organisation: String?) -> UserBuilder {
        storage.organisation = organisation
        return self
    }

    public func setEmail(_ email: String?) -> UserBuilder {
        storage.email = email
        return self
    }

    public func setHashedEmail(_ hashedEmail: String?) -> UserBuilder {
        storage.hashedEmail = hashedEmail
        return self
    }

    public func setMobile(_ mobile: String?) -> UserBuilder {
        storage.mobile = mobile
        return self
    }

    public func setHashedMobile(_ hashedMobile: String?) -> UserBuilder {
        storage.hashedMobile = hashedMobile
        return self
    }

    public func setDateOfBirth(_ dateOfBirth: String?) -> UserBuilder {
        storage.dateOfBirth = dateOfBirth
        return self
    }

    public func setGender(_ gender: String?) -> UserBuilder {
        storage.gender = gender
        return self
    }

    public func setCity(_ city: String?) -> UserBuilder {
        storage.city = city
        return self
    }

    public func setState(_ state: String?) -> UserBuilder {
        storage.state = state
        return self
    }

    public func setCountry(_ country: String?) -> UserBuilder {
        storage.country = country
        return self
    }

    public func setZipCode(_ zipCode: String?) -> UserBuilder {
        storage.zipCode = zipCode
        return self
    }

    public func setHcpId(_ hcpId: String?) -> UserBuilder {
        storage.hcpId = hcpId
        return self
    }

    public func setHashedHcpId(_ hashedHcpId: String?) -> UserBuilder {
        storage.hashedHcpId = hashedHcpId
        return self
    }

    public func build() -> Hcp {
        storage.build(defaultRole: .user)
    }
}
