import Foundation

public enum DocereeUserRole: String {
    case hcp = "hcp"
    case ha = "ha"
    case user = "user"

    static func fromStoredRawValue(_ rawValue: String) -> DocereeUserRole? {
        if rawValue == "consumer" || rawValue == "dtc" { return .user }
        return DocereeUserRole(rawValue: rawValue)
    }
}

/// Builds a profile that can be passed to `DocereeMobileAds.login(with:)`.
/// The SDK derives the active user type from the concrete builder class — clients must not set role.
public protocol DocereeProfileBuilding {
    func build() -> Hcp
}

/// Shared field storage used by all public profile builders.
struct HcpProfileBuilderStorage {
    var firstName: String?
    var lastName: String?
    var specialization: String?
    var userType: String?
    var organisation: String?
    var gender: String?
    var city: String?
    var zipCode: String?
    var email: String?
    var mobile: String?
    var dateOfBirth: String?
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
    var patientId: String?
    var hashedPatientId: String?

    func build(defaultRole: DocereeUserRole = .hcp) -> Hcp {
        Hcp.make(from: self, role: defaultRole)
    }
}

public final class Hcp: NSObject, NSSecureCoding {

    let role: DocereeUserRole
    let firstName: String?
    let lastName: String?
    let specialization: String?
    let userType: String?
    let organisation: String?
    let gender: String?
    let city: String?
    let zipCode: String?
    let email: String?
    let mobile: String?
    let dateOfBirth: String?
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
    let patientId: String?
    let hashedPatientId: String?

    public var fullName: String {
        [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Preferred HCP identifier from `hcpId`.
    var resolvedHcpIdentifier: String {
        if let hcpId, !hcpId.isEmpty { return hcpId }
        return ""
    }

    private struct Fields {
        var role: DocereeUserRole = .hcp
        var firstName: String?
        var lastName: String?
        var specialization: String?
        var userType: String?
        var organisation: String?
        var gender: String?
        var city: String?
        var zipCode: String?
        var email: String?
        var mobile: String?
        var dateOfBirth: String?
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
        var patientId: String?
        var hashedPatientId: String?
    }

    private init(fields: Fields) {
        role = fields.role
        firstName = fields.firstName
        lastName = fields.lastName
        specialization = fields.specialization
        userType = fields.userType
        organisation = fields.organisation
        gender = fields.gender
        city = fields.city
        zipCode = fields.zipCode
        email = fields.email
        mobile = fields.mobile
        dateOfBirth = fields.dateOfBirth
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
        patientId = fields.patientId
        hashedPatientId = fields.hashedPatientId
    }

    func applyingRole(_ role: DocereeUserRole) -> Hcp {
        var fields = asFields()
        fields.role = role
        return Hcp(fields: fields)
    }

    private func asFields() -> Fields {
        Fields(
            role: role,
            firstName: firstName,
            lastName: lastName,
            specialization: specialization,
            userType: userType,
            organisation: organisation,
            gender: gender,
            city: city,
            zipCode: zipCode,
            email: email,
            mobile: mobile,
            dateOfBirth: dateOfBirth,
            hashedEmail: hashedEmail,
            hashedMobile: hashedMobile,
            state: state,
            country: country,
            hcpId: hcpId,
            hashedHcpId: hashedHcpId,
            associateId: associateId,
            hashedAssociateId: hashedAssociateId,
            associateRole: associateRole,
            department: department,
            clinicalInfluenceTier: clinicalInfluenceTier,
            patientId: patientId,
            hashedPatientId: hashedPatientId
        )
    }

    static func make(from storage: HcpProfileBuilderStorage, role: DocereeUserRole) -> Hcp {
        Hcp(fields: Fields(
            role: role,
            firstName: storage.firstName,
            lastName: storage.lastName,
            specialization: storage.specialization,
            userType: storage.userType,
            organisation: storage.organisation,
            gender: storage.gender,
            city: storage.city,
            zipCode: storage.zipCode,
            email: storage.email,
            mobile: storage.mobile,
            dateOfBirth: storage.dateOfBirth,
            hashedEmail: storage.hashedEmail,
            hashedMobile: storage.hashedMobile,
            state: storage.state,
            country: storage.country,
            hcpId: storage.hcpId,
            hashedHcpId: storage.hashedHcpId,
            associateId: storage.associateId,
            hashedAssociateId: storage.hashedAssociateId,
            associateRole: storage.associateRole,
            department: storage.department,
            clinicalInfluenceTier: storage.clinicalInfluenceTier,
            patientId: storage.patientId,
            hashedPatientId: storage.hashedPatientId
        ))
    }

    public func encode(with coder: NSCoder) {
        coder.encode(role.rawValue, forKey: ArchiveKey.role)
        coder.encode(firstName, forKey: ArchiveKey.firstName)
        coder.encode(lastName, forKey: ArchiveKey.lastName)
        coder.encode(specialization, forKey: ArchiveKey.specialization)
        coder.encode(userType, forKey: ArchiveKey.userType)
        coder.encode(organisation, forKey: ArchiveKey.organisation)
        coder.encode(gender, forKey: ArchiveKey.gender)
        coder.encode(city, forKey: ArchiveKey.city)
        coder.encode(zipCode, forKey: ArchiveKey.zipCode)
        coder.encode(email, forKey: ArchiveKey.email)
        coder.encode(mobile, forKey: ArchiveKey.mobile)
        coder.encode(dateOfBirth, forKey: ArchiveKey.dateOfBirth)
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
        coder.encode(patientId, forKey: ArchiveKey.patientId)
        coder.encode(hashedPatientId, forKey: ArchiveKey.hashedPatientId)
    }

    required convenience public init?(coder: NSCoder) {
        self.init(fields: Fields(
            role: Self.decodeRole(coder),
            firstName: Self.decodeString(coder, forKey: ArchiveKey.firstName),
            lastName: Self.decodeString(coder, forKey: ArchiveKey.lastName),
            specialization: Self.decodeString(coder, forKey: ArchiveKey.specialization),
            userType: Self.decodeString(coder, forKey: ArchiveKey.userType),
            organisation: Self.decodeString(coder, forKey: ArchiveKey.organisation),
            gender: Self.decodeString(coder, forKey: ArchiveKey.gender),
            city: Self.decodeString(coder, forKey: ArchiveKey.city),
            zipCode: Self.decodeString(coder, forKey: ArchiveKey.zipCode),
            email: Self.decodeString(coder, forKey: ArchiveKey.email),
            mobile: Self.decodeString(coder, forKey: ArchiveKey.mobile),
            dateOfBirth: Self.decodeString(coder, forKey: ArchiveKey.dateOfBirth),
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
            clinicalInfluenceTier: Self.decodeInt(coder, forKey: ArchiveKey.clinicalInfluenceTier),
            patientId: Self.decodeString(coder, forKey: ArchiveKey.patientId),
            hashedPatientId: Self.decodeString(coder, forKey: ArchiveKey.hashedPatientId)
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
              let role = DocereeUserRole.fromStoredRawValue(rawValue) else {
            return .hcp
        }
        return role
    }

    private static func decodeInt(_ coder: NSCoder, forKey key: String) -> Int? {
        coder.decodeObject(of: NSNumber.self, forKey: key)?.intValue
    }
}

private enum ArchiveKey {
    static let role = "role"
    static let firstName = "firstname"
    static let lastName = "lastname"
    static let specialization = "specialization"
    static let userType = "userType"
    static let organisation = "organisation"
    static let gender = "gender"
    static let city = "city"
    static let zipCode = "zipcode"
    static let email = "email"
    static let mobile = "mobile"
    static let dateOfBirth = "dateOfBirth"
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
    static let patientId = "patientId"
    static let hashedPatientId = "hashedPatientId"
}
