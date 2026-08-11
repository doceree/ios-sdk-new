import Foundation

/// Builds an HCP profile for `DocereeMobileAds.login(with:)`.
public final class HcpBuilder: DocereeProfileBuilding {

    private var storage = HcpProfileBuilderStorage()

    public init() {}

    public func setFirstName(_ firstName: String?) -> HcpBuilder {
        storage.firstName = firstName
        return self
    }

    public func setLastName(_ lastName: String?) -> HcpBuilder {
        storage.lastName = lastName
        return self
    }

    public func setSpecialization(_ specialization: String?) -> HcpBuilder {
        storage.specialization = specialization
        return self
    }

    public func setOrganisation(_ organisation: String?) -> HcpBuilder {
        storage.organisation = organisation
        return self
    }

    public func setGender(_ gender: String?) -> HcpBuilder {
        storage.gender = gender
        return self
    }

    public func setCity(_ city: String?) -> HcpBuilder {
        storage.city = city
        return self
    }

    public func setState(_ state: String?) -> HcpBuilder {
        storage.state = state
        return self
    }

    public func setCountry(_ country: String?) -> HcpBuilder {
        storage.country = country
        return self
    }

    public func setZipCode(_ zipCode: String?) -> HcpBuilder {
        storage.zipCode = zipCode
        return self
    }

    public func setEmail(_ email: String?) -> HcpBuilder {
        storage.email = email
        return self
    }

    public func setMobile(_ mobile: String?) -> HcpBuilder {
        storage.mobile = mobile
        return self
    }

    public func setDateOfBirth(_ dateOfBirth: String?) -> HcpBuilder {
        storage.dateOfBirth = dateOfBirth
        return self
    }

    public func setHashedEmail(_ hashedEmail: String?) -> HcpBuilder {
        storage.hashedEmail = hashedEmail
        return self
    }

    public func setHashedMobile(_ hashedMobile: String?) -> HcpBuilder {
        storage.hashedMobile = hashedMobile
        return self
    }

    public func setHcpId(_ hcpId: String?) -> HcpBuilder {
        storage.hcpId = hcpId
        return self
    }

    public func setHashedHcpId(_ hashedHcpId: String?) -> HcpBuilder {
        storage.hashedHcpId = hashedHcpId
        return self
    }

    @available(*, deprecated, message: "Use DocereeMobileAds.shared().getProfile()?.fullName instead.")
    public func getName() -> String {
        DocereeMobileAds.shared().getProfile()?.fullName ?? ""
    }

    public func build() -> Hcp {
        storage.build(defaultRole: .hcp)
    }
}
