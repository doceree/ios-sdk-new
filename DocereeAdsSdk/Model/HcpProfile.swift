
import Foundation

public final class Hcp: NSObject, NSSecureCoding, Encodable {
   
    // MARK: Properties
    var firstName: String?
    var lastName: String?
    var specialization: String?
    var organisation: String?
    var gender: String?
    var city: String?
    var zipCode: String?
    var email: String?
    var mobile: String?
    var mciRegistrationNumber: String?
    var gmc: String?
    var hashedGMC: String?
    var npi: String?
    var hashedNPI: String?
    var hashedEmail: String?
    var state: String?
    var country: String?
    var hcpId: String?
    var hashedHcpId: String?
    

    private init(builder: HcpBuilder) {
        self.firstName = builder.firstName
        self.lastName = builder.lastName
        self.specialization = builder.specialization
        self.organisation = builder.organisation
        self.gender = builder.gender
        self.city = builder.city
        self.zipCode = builder.zipCode
        self.email = builder.email
        self.mobile = builder.mobile
        self.mciRegistrationNumber = builder.mciRegistrationNumber
        self.gmc = builder.gmc
        self.hashedGMC = builder.hashedGMC
        self.npi = builder.npi
        self.hashedEmail = builder.hashedEmail
        self.hashedNPI = builder.hashedNPI
        self.state = builder.state
        self.country = builder.country
        self.hcpId = builder.hcpId
        self.hashedHcpId = builder.hashedHcpId
    }
    
    private init(firstName: String?, lastName: String?, specialization: String?, organisation: String?, gender: String?, city: String?, zipCode: String?, email: String?, mobile: String?, mciRegistrationNumber: String?,  gmc: String?, hashedGMC: String?, npi: String?, hashedNPI: String?, hashedEmail: String?, state: String?, country: String?, hcpId: String?, hashedHcpId: String?) {
        self.firstName = firstName
        self.lastName = lastName
        self.specialization = specialization
        self.organisation = organisation
        self.gender = gender
        self.city = city
        self.zipCode = zipCode
        self.email = email
        self.mobile = mobile
        self.mciRegistrationNumber = mciRegistrationNumber
        self.gmc = gmc
        self.hashedGMC = hashedGMC
        self.npi = npi
        self.hashedEmail = hashedEmail
        self.hashedNPI = hashedNPI
        self.state = state
        self.country = country
        self.hcpId = hcpId
        self.hashedHcpId = hashedHcpId
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(firstName, forKey: HcpProfile.firstName)
        coder.encode(lastName, forKey: HcpProfile.lastName)
        coder.encode(specialization, forKey: HcpProfile.specialization)
        coder.encode(organisation, forKey: HcpProfile.organisation)
        coder.encode(gender, forKey: HcpProfile.gender)
        coder.encode(city, forKey: HcpProfile.city)
        coder.encode(zipCode, forKey: HcpProfile.zipCode)
        coder.encode(email, forKey: HcpProfile.email)
        coder.encode(mobile, forKey: HcpProfile.mobile)
        coder.encode(mciRegistrationNumber, forKey: HcpProfile.mciRegistrationNumber)
        coder.encode(gmc, forKey: HcpProfile.gmc)
        coder.encode(hashedGMC, forKey: HcpProfile.hashedGMC)
        coder.encode(npi, forKey: HcpProfile.npi)
        coder.encode(hashedNPI, forKey: HcpProfile.hashedNPI)
        coder.encode(hashedEmail, forKey: HcpProfile.hashedEmail)
        coder.encode(state, forKey: HcpProfile.state)
        coder.encode(country, forKey: HcpProfile.country)
        coder.encode(hcpId, forKey: HcpProfile.hcpId)
        coder.encode(hashedHcpId, forKey: HcpProfile.hashedHcpId)
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        let firstName = aDecoder.decodeObject(forKey: HcpProfile.firstName) as? String
        let lastName = aDecoder.decodeObject(forKey: HcpProfile.lastName) as? String
        let specialization = aDecoder.decodeObject(forKey: HcpProfile.specialization) as? String
        let organisation = aDecoder.decodeObject(forKey: HcpProfile.organisation) as? String
        let gender = aDecoder.decodeObject(forKey: HcpProfile.gender) as? String
        let city = aDecoder.decodeObject(forKey: HcpProfile.city) as? String
        let zipcode = aDecoder.decodeObject(forKey: HcpProfile.zipCode) as? String
        let email = aDecoder.decodeObject(forKey: HcpProfile.email) as? String
        let mobile = aDecoder.decodeObject(forKey: HcpProfile.mobile) as? String
        let mciRegistrationNumber = aDecoder.decodeObject(forKey: HcpProfile.mciRegistrationNumber) as? String
        let gmc = aDecoder.decodeObject(forKey: HcpProfile.gmc) as? String
        let hashedGMC = aDecoder.decodeObject(forKey: HcpProfile.hashedGMC) as? String
        let npi = aDecoder.decodeObject(forKey: HcpProfile.npi) as? String
        let hashedNPI = aDecoder.decodeObject(forKey: HcpProfile.hashedNPI) as? String
        let hashedEmail = aDecoder.decodeObject(forKey: HcpProfile.hashedEmail) as? String
        let state = aDecoder.decodeObject(forKey: HcpProfile.state) as? String
        let country = aDecoder.decodeObject(forKey: HcpProfile.country) as? String
        let hcpId = aDecoder.decodeObject(forKey: HcpProfile.hcpId) as? String
        let hashedHcpId = aDecoder.decodeObject(forKey: HcpProfile.hashedHcpId) as? String
       
        self.init(firstName: firstName, lastName: lastName, specialization: specialization, organisation: organisation, gender: gender, city: city, zipCode: zipcode, email: email, mobile: mobile, mciRegistrationNumber: mciRegistrationNumber, gmc: gmc, hashedGMC: hashedGMC, npi: npi, hashedNPI: hashedNPI, hashedEmail: hashedEmail, state: state, country: country, hcpId: hcpId, hashedHcpId: hashedHcpId)
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    public class HcpBuilder {
        
        public init(){}
        
        var firstName: String?
        var lastName: String?
        var specialization: String?
        var organisation: String?
        var gender: String?
        var city: String?
        var zipCode: String?
        var email: String?
        var mobile: String?
        var mciRegistrationNumber: String?
        var gmc: String?
        var hashedGMC: String?
        var npi: String?
        var hashedNPI: String?
        var hashedEmail: String?
        var state: String?
        var country: String?
        var hcpId: String?
        var hashedHcpId: String?
        
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

        
        public func getName() -> String {
            guard let loggedInUser = DocereeMobileAds.shared().getProfile() else {
                return ""
            }
            
            var name = ""
            if let fn = loggedInUser.firstName {
                name = fn + " "
            }
            if let ln = loggedInUser.lastName {
                name = name + ln
            }
                
            return name
        }
        
        public func build() -> Hcp {
            return Hcp(builder: self)
        }
    }
}

struct HcpProfile {
    static let firstName = "firstname"
    static let lastName = "lastname"
    static let specialization = "specialization"
    static let organisation = "organisation"
    static let gender = "gender"
    static let city = "city"
    static let zipCode = "zipcode"
    static let email = "email"
    static let mobile = "mobile"
    static let mciRegistrationNumber = "mciregistrationnumber"
    static let gmc = "gmc"
    static let hashedGMC = "hashedGMC"
    static let npi = "npi"
    static let hashedNPI = "hashedNPI"
    static let hashedEmail = "hashedEmail"
    static let state = "state"
    static let country = "country"
    static let hcpId = "hcpId"
    static let hashedHcpId = "hashedHcpId"
}
