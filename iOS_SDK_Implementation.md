# Doceree Mobile Ads SDK — iOS Implementation Guide

Integration patterns for the Doceree iOS SDK.

All data attributes use one public API:

```swift
DocereeMobileAds.shared().add(key, value:)
```

`DocereeMobileAds.shared().add(key, value:)` persists data attributes locally. The SDK includes them automatically on subsequent ad requests.

Optional key constants:

```swift
DocereeMobileAds.patientDetailsKey   // "patientDetails"
DocereeMobileAds.sessionDetailsKey   // "sessionDetails"
DocereeMobileAds.actionEventKey      // "actionEvent"
```

---

## Table of Contents

1. [Consent (`setConsent`)](#1-consent-setconsent)
2. [HCP Login](#2-hcp-login-hcpbuilder)
3. [Health Associate Login](#3-health-associate-login-healthassociatebuilder)
4. [Generic User Login](#4-generic-user-login-userbuilder)
5. [Patient Data Initialization](#5-patient-data-initialization)
6. [Session Attribute Call](#6-session-attribute-call)
7. [Action Attribute Call](#7-action-attribute-call)
8. [Universal IDs (`setUniversalIds`)](#8-universal-ids-setuniversalids)

---

## 1. Consent (`setConsent`)

`DocereeConsentBuilder` has 10 setter methods. Pass whichever fields apply — non-nil values merge with consent already stored.

```swift
import DocereeAdsSdk

DocereeMobileAds.shared().setConsent(
    DocereeConsentBuilder()
        .setUserConsent("1")
        .setPrivacyType("tcf")
        .setPrivacyString("1YNN")
        .setPrivacyVersion("2.0")
        .setPrivacySid("1,2,3,7")
        .setConsentBasis("publisher_attested")
        .setMechanism("publisher_onboarding")
        .setGrantedAt("2026-08-05T10:00:00Z")
        .setExpiresAt("2027-08-05T10:00:00Z")
        .setConsentReferenceId("CONSENT-HCP-1001")
        .build()
)

DocereeMobileAds.shared().clearConsent()
```

If no consent is stored, the SDK falls back to IAB TCF/GPP keys in `UserDefaults.standard`.

> Pass GPP section IDs as a comma-separated string (e.g. `"2,6"`) or an array via `setPrivacySid(["2", "6"])`.

---

## 2. HCP Login (`HcpBuilder`)

```swift
import DocereeAdsSdk

let hcp = HcpBuilder()
    .setHcpId("HCP-10234")
    .setHashedHcpId("sha256:1a2b3c4d5e6f7890")
    .setFirstName("John")
    .setLastName("Doe")
    .setSpecialization("Cardiology")
    .setOrganisation("City General Hospital")
    .setEmail("john.doe@example.com")
    .setHashedEmail("sha256:9f8e7d6c5b4a3210")
    .setMobile("+1-555-123-4567")
    .setHashedMobile("sha256:8e7d6c5b4a32109f")
    .setDateOfBirth("1985-06-15")
    .setGender("M")
    .setCity("New York")
    .setState("NY")
    .setCountry("US")
    .setZipCode("10001")
    .build()

DocereeMobileAds.login(with: hcp)
```

---

## 3. Health Associate Login (`HealthAssociateBuilder`)

```swift
import DocereeAdsSdk

let healthAssociate = HealthAssociateBuilder()
    .setAssociateId("HA-55021")
    .setHashedAssociateId("sha256:aa11bb22cc33dd44")
    .setAssociateRole("Nurse Practitioner")
    .setDepartment("Cardiology")
    .setFirstName("Jane")
    .setLastName("Smith")
    .setOrganisation("City General Hospital")
    .setClinicalInfluenceTier(2)
    .setEmail("jane.smith@example.com")
    .setMobile("+1-555-987-6543")
    .setHashedEmail("sha256:11aa22bb33cc44dd")
    .setDateOfBirth("1990-03-22")
    .setGender("F")
    .setCity("New York")
    .setState("NY")
    .setCountry("US")
    .setZipCode("10001")
    .build()

DocereeMobileAds.login(with: healthAssociate)
```

---

## 4. Generic User Login (`UserBuilder`)

Use when the logged-in person is neither an HCP nor a Health Associate.

```swift
import DocereeAdsSdk

let user = UserBuilder()
    .setHcpId("USR-3301")
    .setFirstName("Alex")
    .setLastName("Taylor")
    .setSpecialization("General Practice")
    .setGender("M")
    .setEmail("alex.taylor@example.com")
    .setMobile("+1-555-222-3333")
    .setCity("Boston")
    .setState("MA")
    .setZipCode("02108")
    .build()

DocereeMobileAds.login(with: user)
```

---

## 5. Patient Data Initialization

Patient data is a JSON object passed with key `"patientDetails"`.

```swift
import DocereeAdsSdk

let consent: [String: Any] = [
    "consentBasis": "publisher_attested",
    "mechanism": "patient_portal",
    "grantedAt": "2026-08-05T10:00:00Z",
    "expiresAt": "2027-08-05T10:00:00Z",
    "consentReferenceId": "CONSENT-PAT-9001"
]

let insurance: [String: Any] = [
    "hasInsurance": 1,
    "insuranceType": 1,
    "insuranceName": "Acme Health",
    "insurancePlanName": "Gold PPO",
    "insurancePlanId": "PLAN-778-XY",
    "insuranceGroupId": "GRP-4021",
    "insuranceMemberId": "MEM123456789",
    "policyholderName": "Sam Patient",
    "policyholderDob": "1978-11-02",
    "relationshipToPolicyholder": "self",
    "primaryPayerPhone": "+1-800-555-0100"
]

let allergy: [String: Any] = [
    "allergen": "Penicillin",
    "allergenType": "drug",
    "reaction": "rash",
    "severity": "moderate",
    "onsetDate": "2020-05-10",
    "status": "active"
]

let clinicalProfile: [String: Any] = [
    "smokingStatus": "never",
    "newAllergies": [allergy]
]

let patientData: [String: Any] = [
    "consent": consent,
    "patientId": "PT-88012",
    "hashedId": "sha256:5566778899aabbcc",
    "name": "Sam Patient",
    "insurance": insurance,
    "dob": "1978-11-02",
    "age": "47",
    "gender": "M",
    "email": "sam.patient@example.com",
    "mobile": "+1-555-444-7890",
    "zipCode": "10001",
    "clinicalProfile": clinicalProfile
]

DocereeMobileAds.shared().add("patientDetails", value: patientData)
```

---

## 6. Session Attribute Call

Start the session first when the clinical visit begins. Then pass session context with key `"sessionDetails"`. Multiple `add` calls with the same key are merged together.

```swift
import DocereeAdsSdk

DocereeMobileAds.shared().startSession()

let sessionAttributes: [String: Any] = [
    "sessionType": "clinical",
    "context": "EMR",
    "department": "Cardiology",
    "visitType": "Follow-up",
    "duration": 30,
    "patientCount": 12
]
DocereeMobileAds.shared().add("sessionDetails", value: sessionAttributes)

let sessionStart: [String: Any] = ["session": 1]
DocereeMobileAds.shared().add("sessionDetails", value: sessionStart)

let temperature: [String: Any] = ["v": 98.6, "u": "F"]
let vitals: [String: Any] = [
    "bloodPressureSystolic": 120,
    "bloodPressureDiastolic": 80,
    "heartRate": 72,
    "temperature": temperature
]
DocereeMobileAds.shared().add("sessionDetails", value: vitals)

// ...later, to end the session
let sessionEnd: [String: Any] = ["session": 0]
DocereeMobileAds.shared().add("sessionDetails", value: sessionEnd)
DocereeMobileAds.shared().closeSession()
```

> `startSession()` and `closeSession()` run asynchronously on iOS. Call `startSession()` once at the beginning of the visit, then update `sessionDetails` as context changes.

---

## 7. Action Attribute Call

```swift
import DocereeAdsSdk

let reason: [String: Any] = [
    "chiefComplaint": "Chest discomfort",
    "symptomDuration": "2 days",
    "symptomSeverity": 3,
    "visitContext": "urgent"
]

let actionEvent: [String: Any] = [
    "type": "appt_request",
    "timestamp": "2026-08-05T10:00:00Z",
    "appointmentId": "APT-778-XY",
    "patientId": "PT-88012",
    "appointmentDate": "2026-08-10",
    "appointmentTime": "14:30",
    "visitType": "Follow-up",
    "hcpId": "HCP-10234",
    "visitUrgency": "high",
    "facilityName": "City General Hospital",
    "reasonForVisit": [reason]
]

DocereeMobileAds.shared().add("actionEvent", value: actionEvent)
```

Supported `type` values: `appt_request`, `appt_confirmed`, `appt_rescheduled`, `referral`, `patient_checked_in`, `checkout`.

Only one event per `type` is kept — adding the same type again updates the stored event.

---

## 8. Universal IDs (`setUniversalIds`)

Persists third-party universal identifiers for subsequent ad requests.

```swift
import DocereeAdsSdk

// Full signature
DocereeMobileAds.shared().setUniversalIds(
    rampId: "ramp-id-abc123",
    uid2: "uid2-token-xyz789",
    id5: "id5-token-def456",
    liveIntentId: "live-intent-ghi000"
)

// Partial — trailing parameters default to empty strings
DocereeMobileAds.shared().setUniversalIds(rampId: "ramp-id-abc123")
DocereeMobileAds.shared().setUniversalIds(rampId: "ramp-id-abc123", uid2: "uid2-token-xyz789")
```
