import Foundation

public enum DocereeUserRole: String {
    case hcp = "hcp"
    case ha = "ha"
}

public final class Hcp: NSObject, NSSecureCoding {

    let role: DocereeUserRole
    let firstName: String?
    let lastName: String?
    let specialization: String?
    let organisation: String?
    let gender: String?
    let city: String?
    let zipCode: String?
    let email: String?
    let mobile: String?
    let dateOfBirth: String?
    let mciRegistrationNumber: String?
    let gmc: String?
    let hashedGMC: String?
    let npi: String?
    let hashedNPI: String?
    let hashedEmail: String?
    let hashedMobile: String?
    let state: String?
    let country: String?
    let hcpId: String?
    let hashedHcpId: String?
    let associateId: String?
    let hashedAssociateId: String?
    let associateRole: String?
    let department: String?
    let clinicalInfluenceTier: Int?

    public var fullName: String {
        [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private struct Fields {
        var role: DocereeUserRole = .hcp
        var firstName: String?
        var lastName: String?
        var specialization: String?
        var organisation: String?
        var gender: String?
        var city: String?
        var zipCode: String?
        var email: String?
        var mobile: String?
        var dateOfBirth: String?
        var mciRegistrationNumber: String?
        var gmc: String?
        var hashedGMC: String?
        var npi: String?
        var hashedNPI: String?
        var hashedEmail: String?
        var hashedMobile: String?
        var state: String?
        var country: String?
        var hcpId: String?
        var hashedHcpId: String?
        var associateId: String?
        var hashedAssociateId: String?
        var associateRole: String?
        var department: String?
        var clinicalInfluenceTier: Int?
    }

    private init(fields: Fields) {
        role = fields.role
        firstName = fields.firstName
        lastName = fields.lastName
        specialization = fields.specialization
        organisation = fields.organisation
        gender = fields.gender
        city = fields.city
        zipCode = fields.zipCode
        email = fields.email
        mobile = fields.mobile
        dateOfBirth = fields.dateOfBirth
        mciRegistrationNumber = fields.mciRegistrationNumber
        gmc = fields.gmc
        hashedGMC = fields.hashedGMC
        npi = fields.npi
        hashedNPI = fields.hashedNPI
        hashedEmail = fields.hashedEmail
        hashedMobile = fields.hashedMobile
        state = fields.state
        country = fields.country
        hcpId = fields.hcpId
        hashedHcpId = fields.hashedHcpId
        associateId = fields.associateId
        hashedAssociateId = fields.hashedAssociateId
        associateRole = fields.associateRole
        department = fields.department
        clinicalInfluenceTier = fields.clinicalInfluenceTier
    }

    private convenience init(builder: HcpBuilder) {
        self.init(fields: Fields(
            role: builder.role,
            firstName: builder.firstName,
            lastName: builder.lastName,
            specialization: builder.specialization,
            organisation: builder.organisation,
            gender: builder.gender,
            city: builder.city,
            zipCode: builder.zipCode,
            email: builder.email,
            mobile: builder.mobile,
            dateOfBirth: builder.dateOfBirth,
            mciRegistrationNumber: builder.mciRegistrationNumber,
            gmc: builder.gmc,
            hashedGMC: builder.hashedGMC,
            npi: builder.npi,
            hashedNPI: builder.hashedNPI,
            hashedEmail: builder.hashedEmail,
            hashedMobile: builder.hashedMobile,
            state: builder.state,
            country: builder.country,
            hcpId: builder.hcpId,
            hashedHcpId: builder.hashedHcpId,
            associateId: builder.associateId,
            hashedAssociateId: builder.hashedAssociateId,
            associateRole: builder.associateRole,
            department: builder.department,
            clinicalInfluenceTier: builder.clinicalInfluenceTier
        ))
    }

    public func encode(with coder: NSCoder) {
        coder.encode(role.rawValue, forKey: ArchiveKey.role)
        coder.encode(firstName, forKey: ArchiveKey.firstName)
        coder.encode(lastName, forKey: ArchiveKey.lastName)
        coder.encode(specialization, forKey: ArchiveKey.specialization)
        coder.encode(organisation, forKey: ArchiveKey.organisation)
        coder.encode(gender, forKey: ArchiveKey.gender)
        coder.encode(city, forKey: ArchiveKey.city)
        coder.encode(zipCode, forKey: ArchiveKey.zipCode)
        coder.encode(email, forKey: ArchiveKey.email)
        coder.encode(mobile, forKey: ArchiveKey.mobile)
        coder.encode(dateOfBirth, forKey: ArchiveKey.dateOfBirth)
        coder.encode(mciRegistrationNumber, forKey: ArchiveKey.mciRegistrationNumber)
        coder.encode(gmc, forKey: ArchiveKey.gmc)
        coder.encode(hashedGMC, forKey: ArchiveKey.hashedGMC)
        coder.encode(npi, forKey: ArchiveKey.npi)
        coder.encode(hashedNPI, forKey: ArchiveKey.hashedNPI)
        coder.encode(hashedEmail, forKey: ArchiveKey.hashedEmail)
        coder.encode(hashedMobile, forKey: ArchiveKey.hashedMobile)
        coder.encode(state, forKey: ArchiveKey.state)
        coder.encode(country, forKey: ArchiveKey.country)
        coder.encode(hcpId, forKey: ArchiveKey.hcpId)
        coder.encode(hashedHcpId, forKey: ArchiveKey.hashedHcpId)
        coder.encode(associateId, forKey: ArchiveKey.associateId)
        coder.encode(hashedAssociateId, forKey: ArchiveKey.hashedAssociateId)
        coder.encode(associateRole, forKey: ArchiveKey.associateRole)
        coder.encode(department, forKey: ArchiveKey.department)
        if let clinicalInfluenceTier {
            coder.encode(NSNumber(value: clinicalInfluenceTier), forKey: ArchiveKey.clinicalInfluenceTier)
        }
    }

    required convenience public init?(coder: NSCoder) {
        self.init(fields: Fields(
            role: Self.decodeRole(coder),
            firstName: Self.decodeString(coder, forKey: ArchiveKey.firstName),
            lastName: Self.decodeString(coder, forKey: ArchiveKey.lastName),
            specialization: Self.decodeString(coder, forKey: ArchiveKey.specialization),
            organisation: Self.decodeString(coder, forKey: ArchiveKey.organisation),
            gender: Self.decodeString(coder, forKey: ArchiveKey.gender),
            city: Self.decodeString(coder, forKey: ArchiveKey.city),
            zipCode: Self.decodeString(coder, forKey: ArchiveKey.zipCode),
            email: Self.decodeString(coder, forKey: ArchiveKey.email),
            mobile: Self.decodeString(coder, forKey: ArchiveKey.mobile),
            dateOfBirth: Self.decodeString(coder, forKey: ArchiveKey.dateOfBirth),
            mciRegistrationNumber: Self.decodeString(coder, forKey: ArchiveKey.mciRegistrationNumber),
            gmc: Self.decodeString(coder, forKey: ArchiveKey.gmc),
            hashedGMC: Self.decodeString(coder, forKey: ArchiveKey.hashedGMC),
            npi: Self.decodeString(coder, forKey: ArchiveKey.npi),
            hashedNPI: Self.decodeString(coder, forKey: ArchiveKey.hashedNPI),
            hashedEmail: Self.decodeString(coder, forKey: ArchiveKey.hashedEmail),
            hashedMobile: Self.decodeString(coder, forKey: ArchiveKey.hashedMobile),
            state: Self.decodeString(coder, forKey: ArchiveKey.state),
            country: Self.decodeString(coder, forKey: ArchiveKey.country),
            hcpId: Self.decodeString(coder, forKey: ArchiveKey.hcpId),
            hashedHcpId: Self.decodeString(coder, forKey: ArchiveKey.hashedHcpId),
            associateId: Self.decodeString(coder, forKey: ArchiveKey.associateId),
            hashedAssociateId: Self.decodeString(coder, forKey: ArchiveKey.hashedAssociateId),
            associateRole: Self.decodeString(coder, forKey: ArchiveKey.associateRole),
            department: Self.decodeString(coder, forKey: ArchiveKey.department),
            clinicalInfluenceTier: Self.decodeInt(coder, forKey: ArchiveKey.clinicalInfluenceTier)
        ))
    }

    public static var supportsSecureCoding: Bool {
        true
    }

    private static func decodeString(_ coder: NSCoder, forKey key: String) -> String? {
        coder.decodeObject(of: NSString.self, forKey: key) as String?
    }

    private static func decodeRole(_ coder: NSCoder) -> DocereeUserRole {
        guard let rawValue = decodeString(coder, forKey: ArchiveKey.role),
              let role = DocereeUserRole(rawValue: rawValue) else {
            return .hcp
        }
        return role
    }

    private static func decodeInt(_ coder: NSCoder, forKey key: String) -> Int? {
        coder.decodeObject(of: NSNumber.self, forKey: key)?.intValue
    }

    public class HcpBuilder {

        public init() {}

        var role: DocereeUserRole = .hcp
        var firstName: String?
        var lastName: String?
        var specialization: String?
        var organisation: String?
        var gender: String?
        var city: String?
        var zipCode: String?
        var email: String?
        var mobile: String?
        var dateOfBirth: String?
        var mciRegistrationNumber: String?
        var gmc: String?
        var hashedGMC: String?
        var npi: String?
        var hashedNPI: String?
        var hashedEmail: String?
        var hashedMobile: String?
        var state: String?
        var country: String?
        var hcpId: String?
        var hashedHcpId: String?
        var associateId: String?
        var hashedAssociateId: String?
        var associateRole: String?
        var department: String?
        var clinicalInfluenceTier: Int?

        public func setRole(_ role: DocereeUserRole) -> HcpBuilder {
            self.role = role
            return self
        }

        public func setFirstName(firstName: String?) -> HcpBuilder {
            self.firstName = firstName
            return self
        }

        public func setLastName(lastName: String?) -> HcpBuilder {
            self.lastName = lastName
            return self
        }

        public func setSpecialization(specialization: String?) -> HcpBuilder {
            self.specialization = specialization
            return self
        }

        public func setOrganisation(organisation: String?) -> HcpBuilder {
            self.organisation = organisation
            return self
        }

        public func setGender(gender: String?) -> HcpBuilder {
            self.gender = gender
            return self
        }

        public func setCity(city: String?) -> HcpBuilder {
            self.city = city
            return self
        }

        public func setZipCode(zipCode: String?) -> HcpBuilder {
            self.zipCode = zipCode
            return self
        }

        public func setEmail(email: String?) -> HcpBuilder {
            self.email = email
            return self
        }

        public func setMobile(mobile: String?) -> HcpBuilder {
            self.mobile = mobile
            return self
        }

        public func setDateOfBirth(dateOfBirth: String?) -> HcpBuilder {
            self.dateOfBirth = dateOfBirth
            return self
        }

        public func setMciRegistrationNumber(mciRegistrationNumber: String?) -> HcpBuilder {
            self.mciRegistrationNumber = mciRegistrationNumber
            return self
        }

        public func setGmc(gmc: String?) -> HcpBuilder {
            self.gmc = gmc
            return self
        }

        public func setHashedGMC(hashedGMC: String?) -> HcpBuilder {
            self.hashedGMC = hashedGMC
            return self
        }

        public func setNpi(npi: String?) -> HcpBuilder {
            self.npi = npi
            return self
        }

        public func setHashedEmail(hashedEmail: String?) -> HcpBuilder {
            self.hashedEmail = hashedEmail
            return self
        }

        public func setHashedMobile(hashedMobile: String?) -> HcpBuilder {
            self.hashedMobile = hashedMobile
            return self
        }

        public func setHashedNPI(hashedNPI: String?) -> HcpBuilder {
            self.hashedNPI = hashedNPI
            return self
        }

        public func setState(state: String?) -> HcpBuilder {
            self.state = state
            return self
        }

        public func setCountry(country: String?) -> HcpBuilder {
            self.country = country
            return self
        }

        public func setHcpId(hcpId: String?) -> HcpBuilder {
            self.hcpId = hcpId
            return self
        }

        public func setHashedHcpId(hashedHcpId: String?) -> HcpBuilder {
            self.hashedHcpId = hashedHcpId
            return self
        }

        public func setAssociateId(associateId: String?) -> HcpBuilder {
            self.associateId = associateId
            return self
        }

        public func setHashedAssociateId(hashedAssociateId: String?) -> HcpBuilder {
            self.hashedAssociateId = hashedAssociateId
            return self
        }

        public func setAssociateRole(associateRole: String?) -> HcpBuilder {
            self.associateRole = associateRole
            return self
        }

        public func setDepartment(department: String?) -> HcpBuilder {
            self.department = department
            return self
        }

        public func setClinicalInfluenceTier(clinicalInfluenceTier: Int?) -> HcpBuilder {
            self.clinicalInfluenceTier = clinicalInfluenceTier
            return self
        }

        @available(*, deprecated, message: "Use DocereeMobileAds.shared().getProfile()?.fullName instead.")
        public func getName() -> String {
            DocereeMobileAds.shared().getProfile()?.fullName ?? ""
        }

        public func build() -> Hcp {
            Hcp(builder: self)
        }
    }
}

private enum ArchiveKey {
    static let role = "role"
    static let firstName = "firstname"
    static let lastName = "lastname"
    static let specialization = "specialization"
    static let organisation = "organisation"
    static let gender = "gender"
    static let city = "city"
    static let zipCode = "zipcode"
    static let email = "email"
    static let mobile = "mobile"
    static let dateOfBirth = "dateOfBirth"
    static let mciRegistrationNumber = "mciregistrationnumber"
    static let gmc = "gmc"
    static let hashedGMC = "hashedGMC"
    static let npi = "npi"
    static let hashedNPI = "hashedNPI"
    static let hashedEmail = "hashedEmail"
    static let hashedMobile = "hashedMobile"
    static let state = "state"
    static let country = "country"
    static let hcpId = "hcpId"
    static let hashedHcpId = "hashedHcpId"
    static let associateId = "associateId"
    static let hashedAssociateId = "hashedAssociateId"
    static let associateRole = "associateRole"
    static let department = "department"
    static let clinicalInfluenceTier = "clinicalInfluenceTier"
}
