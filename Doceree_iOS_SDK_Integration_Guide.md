# Doceree iOS SDK — Native Integration Guide

**Document version:** 2.2  
**SDK version:** 6.3.2  
**Audience:** Mobile engineering teams (publishers)

This guide matches the **DocereeAdSdk** CocoaPods release **6.3.2**. Payload field rules live in the **Doceree Platform Integration Guide** ([§3.9](#39-platform-integration-guide)).

---

## Table of contents

1. [Introduction](#1-introduction)
2. [Core setup and initialization](#2-core-setup-and-initialization)
3. [Compliance, identity, and data attributes](#3-compliance-identity-and-data-attributes)
4. [Ad slot integration (UI)](#4-ad-slot-integration-ui)
5. [Appendix: supported ad sizes](#5-appendix-supported-ad-sizes)

**Quick links:** [Checklist](#16-integration-checklist) · [ATT](#23-app-tracking-transparency-att) · [Lifecycle](#38-identity-and-session-lifecycle) · [Platform Guide](#39-platform-integration-guide) · [Ad errors](#46-handling-ad-load-failures)

---

## 1. Introduction

### 1.1 Description

The Doceree iOS SDK is a native Swift framework for healthcare publishers. It loads ad slots, sends identity and consent signals, and accepts optional clinical/session data for targeting.

### 1.2 System requirements

| Item | Requirement |
|------|-------------|
| Minimum iOS | **15.0** |
| Xcode | **13.0** or later recommended |
| Language | **Swift 5** (Objective-C host apps supported) |
| Distribution | **CocoaPods** (official). Swift Package Manager is **not** supported in this repo. |

### 1.3 Prerequisites

- Doceree Platform Manager access and a live **application key**
- Ad unit IDs from the dashboard
- Test device or simulator on iOS 15+

### 1.4 Import

CocoaPods product: **`DocereeAdSdk`**. In Swift: **`import DocereeAdSdk`** (not `DocereeAdsSdk`).

### 1.5 Hashed identifiers (critical)

The SDK **does not hash** email, mobile, HCP ID, or patient IDs. You must pass **pre-hashed** values on `hashed*` fields.

- **Format:** lowercase **SHA-256 hex**, **64 characters**, **no** `sha256:` prefix unless your platform contract explicitly requires otherwise.
- **Canonicalization** (lowercase email, digits-only ID, etc.) is the **publisher’s** responsibility per the Platform Integration Guide.

Example placeholder (64 hex chars):

```text
a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3
```

### 1.6 Integration checklist

Use this order for a first integration. Details for each step are in the sections linked below.

| Step | Action | Section |
|------|--------|---------|
| 1 | Add **`DocereeAdSdk`** to your Podfile, run **`pod install`**, open **`.xcworkspace`** | [§2.1](#21-cocoapods) |
| 2 | Add **`NSUserTrackingUsageDescription`** to **Info.plist** if you call **`start()`** | [§2.3](#23-app-tracking-transparency-att) |
| 3 | **`DocereeMobileAds.setApplicationKey(_:)`** then **`DocereeMobileAds.shared().start(...)`** at app launch | [§2.2](#22-application-startup) |
| 4 | Publish consent via **`setConsent(_:)`** (or rely on IAB keys already in **`UserDefaults`**) | [§3.1](#31-consent-setconsent) |
| 5 | **`DocereeMobileAds.login(with:)`** with **`HcpBuilder`**, **`HealthAssociateBuilder`**, or **`UserBuilder`**; supply **pre-hashed** values on `hashed*` fields | [§3.2–§3.4](#32-hcp-login-hcpbuilder), [§1.5](#15-hashed-identifiers-critical) |
| 6 | (Optional) Patient / session / action payloads, universal IDs, HCP validation UI | [§3.6–§3.7](#36-data-attributes-api), [§3.5](#35-hcp-self-validation-optional) |
| 7 | Create **`DocereeAdView`**, set **ad unit ID** and **`rootViewController`**, implement **`DocereeAdViewDelegate`**, call **`load(DocereeAdRequest())`** | [§4.1–§4.2](#41-docereeadview-basics) |
| 8 | Verify on a **physical device** or simulator (iOS 15+) with a **live ad unit** from Platform Manager | [§1.3](#13-prerequisites) |

---

## 2. Core setup and initialization

### 2.1 CocoaPods

**Podfile** (CocoaPods trunk or your private spec repo):

```ruby
platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'DocereeAdSdk', '6.3.2'
end
```

Optional **DocereePodSpecs** source (if your org does not use trunk alone):

```ruby
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/doceree/DocereePodSpecs.git'

pod 'DocereeAdSdk', '6.3.2'
```

Then run `pod install` and open the `.xcworkspace`.

### 2.2 Application startup

Set your **application key** from Platform Manager, then start the SDK (ATT prompt on iOS 14+ when applicable). Endpoint selection is handled inside the SDK; publishers do not configure server environments.

```swift
import UIKit
import DocereeAdSdk

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        DocereeMobileAds.setApplicationKey("YOUR-APPLICATION-KEY-UUID")
        DocereeMobileAds.shared().start(completionHandler: nil)

        return true
    }
}
```

Call **`setApplicationKey`** and **`start`** once at launch, before loading ads.

### 2.3 App Tracking Transparency (ATT)

If you use **`start()`**, add **`NSUserTrackingUsageDescription`** to **Info.plist**. On iOS 14+, **`start()`** may show Apple’s tracking permission dialog.

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use your device advertising identifier to deliver and measure relevant healthcare advertising.</string>
```

Use copy approved by your legal/privacy team. Denying tracking does not always block ads; it can limit measurement and targeting.

---

## 3. Compliance, identity, and data attributes

### Recommended privacy order

1. **CMP / IAB** — your consent platform writes TCF/GPP to **`UserDefaults`**, if you use one.
2. **Doceree consent** — **`setConsent(_:)`** when you pass Doceree-specific metadata ([§3.1](#31-consent-setconsent)).
3. **SDK start** — **`setApplicationKey`** and **`start()`** (ATT when applicable) ([§2.2](#22-application-startup), [§2.3](#23-app-tracking-transparency-att)).
4. **Login** — **`login(with:)`** before the user sees ad slots ([§3.2–§3.4](#32-hcp-login-hcpbuilder)).

### 3.1 Consent (`setConsent`)

Use `DocereeConsentBuilder` and `DocereeMobileAds.shared().setConsent(_:)`. Non-nil fields **merge** with stored consent. Call `clearConsent()` to reset; if nothing is stored, the SDK reads **IAB TCF/GPP** keys from `UserDefaults.standard`.

```swift
import DocereeAdSdk

DocereeMobileAds.shared().setConsent(
    DocereeConsentBuilder()
        .setUserConsent("1")
        .setPrivacyType("tcf")          // e.g. tcf, gpp, gdpr — per platform contract
        .setPrivacyString("1YNN")
        .setPrivacyVersion("2.0")
        .setPrivacySid("2,6")          // or .setPrivacySid(["2", "6"])
        .setConsentBasis("publisher_attested")
        .setMechanism("publisher_onboarding")
        .setGrantedAt("2026-08-05T10:00:00Z")
        .setExpiresAt("2027-08-05T10:00:00Z")
        .setConsentReferenceId("CONSENT-HCP-1001")
        .build()
)

// DocereeMobileAds.shared().clearConsent()
```

Legacy overload `setConsentData(...)` exists but is **deprecated**; prefer `DocereeConsentBuilder`.

### 3.2 HCP login (`HcpBuilder`)

```swift
import DocereeAdSdk

DocereeMobileAds.login(with:
    HcpBuilder()
        .setHcpId("HCP-10234")
        .setHashedHcpId("a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3")
        .setFirstName("John")
        .setLastName("Doe")
        .setSpecialization("Cardiology")
        .setOrganisation("City General Hospital")
        .setEmail("john.doe@example.com")
        .setHashedEmail("b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9")
        .setMobile("+1-555-123-4567")
        .setHashedMobile("c84d9f2e7f92b952ba89a147e910f579f352e198789a8b0d0c3d773b6b4cb2a")
        .setDateOfBirth("1985-06-15")
        .setGender("M")
        .setCity("New York")
        .setState("NY")
        .setCountry("US")
        .setZipCode("10001")
)
```

Profile fields are included on ad requests using the field names defined in the Platform Integration Guide. Optional hashed fields are omitted from the request when not set.

`login(with: Hcp)` after `.build()` still works but is **deprecated**; pass the builder directly as shown.

### 3.3 Health associate login (`HealthAssociateBuilder`)

```swift
DocereeMobileAds.login(with:
    HealthAssociateBuilder()
        .setAssociateId("HA-55021")
        .setHashedAssociateId("d44f1a2b3c4d5e6f7890abcdef1234567890abcdef1234567890abcdef123456")
        .setAssociateRole("Nurse Practitioner")
        .setDepartment("Cardiology")
        .setFirstName("Jane")
        .setLastName("Smith")
        .setOrganisation("City General Hospital")
        .setClinicalInfluenceTier(2)
        .setEmail("jane.smith@example.com")
        .setHashedEmail("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        .setMobile("+1-555-987-6543")
        .setHashedMobile("38d8c2b7e3d9f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7")
        .setDateOfBirth("1990-03-22")
        .setGender("F")
        .setCity("New York")
        .setState("NY")
        .setCountry("US")
        .setZipCode("10001")
)
```

### 3.4 Generic user login (`UserBuilder`)

For users who are neither HCP nor health associate:

```swift
DocereeMobileAds.login(with:
    UserBuilder()
        .setUserType("consumer")
        .setFirstName("Alex")
        .setLastName("Taylor")
        .setEmail("alex.taylor@example.com")
        .setHashedEmail("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        .setMobile("+1-555-222-3333")
        .setHashedMobile("38d8c2b7e3d9f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7")
        .setCity("Boston")
        .setState("MA")
        .setCountry("US")
        .setZipCode("02108")
)
```

### 3.5 HCP self-validation (optional)

For out-of-the-box credential verification UI:

```swift
HcpValidationViewManager.showIfNeeded(on: self, delegate: self)
```

Implement `HcpValidationViewDelegate` for success, failure, and popup actions.

### 3.6 Data attributes API

All structured clinical / session payloads use one entry point:

```swift
DocereeMobileAds.shared().add(_ key: String, value: Any)
```

Key constants:

```swift
DocereeMobileAds.patientDetailsKey   // "patientDetails"
DocereeMobileAds.sessionDetailsKey   // "sessionDetails"
DocereeMobileAds.actionEventKey      // "actionEvent"
```

Numeric values in dictionaries are **normalized** for JSON (avoids long floating-point artifacts in payloads).

#### Patient details (`patientDetails`)

```swift
let patientData: [String: Any] = [
    "patientId": "PT-88012",
    "hashedId": "5566778899aabbccddeeff00112233445566778899aabbccddeeff0011223344",
    "name": "Sam Patient",
    "dob": "1978-11-02",
    "gender": "M",
    "hashedEmail": "aa11aabbccdd1122aa11aabbccdd1122aa11aabbccdd1122aa11aabbccdd1122",
    "hashedMobile": "bb22aabbccdd1122bb22aabbccdd1122bb22aabbccdd1122bb22aabbccdd1122",
    "zipCode": "10001"
]

DocereeMobileAds.shared().add(DocereeMobileAds.patientDetailsKey, value: patientData)
```

#### Session (`startSession`, `sessionDetails`, `closeSession`)

```swift
DocereeMobileAds.shared().startSession()

DocereeMobileAds.shared().add(DocereeMobileAds.sessionDetailsKey, value: [
    "sessionType": "clinical",
    "context": "EMR",
    "department": "Cardiology"
])

// End visit
DocereeMobileAds.shared().add(DocereeMobileAds.sessionDetailsKey, value: ["session": 0])
DocereeMobileAds.shared().closeSession()
```

`startSession()` and `closeSession()` run asynchronously; call `startSession()` once per encounter, then merge updates via `add`.

#### Action events (`actionEvent`)

```swift
DocereeMobileAds.shared().add(DocereeMobileAds.actionEventKey, value: [
    "type": "appt_request",
    "timestamp": "2026-08-05T10:00:00Z",
    "appointmentId": "APT-778-XY",
    "patientId": "PT-88012"
])
```

Supported `type` values include: `appt_request`, `appt_confirmed`, `appt_rescheduled`, `referral`, `patient_checked_in`, `checkout`. One stored event per `type` (updates replace the previous).

### 3.7 Universal IDs

```swift
DocereeMobileAds.shared().setUniversalIds(
    rampId: "ramp-id-abc123",
    uid2: "uid2-token-xyz789",
    id5: "id5-token-def456",
    liveIntentId: "live-intent-ghi000"
)
```

Empty strings are omitted from ad requests.

### 3.8 Identity and session lifecycle

| Situation | What to do |
|-----------|------------|
| **New or updated user** | Call **`login(with:)`** again (replaces stored profile). |
| **Another user signs in** | **`login(with:)`** for the new user; stop sending the previous user’s patient/session data from your app. |
| **User signs out** | No logout API. Clear clinical **`add`** data in your app; next sign-in uses **`login(with:)`** again. |
| **End of visit** | **`closeSession()`** and session **`add`** updates per [§3.6](#36-data-attributes-api). |

**`clearUserData()`** wipes everything (including the stored **application key**). Use only for **QA**; then call **`setApplicationKey`** and **`start`** again. Do not use for normal sign-out.

### 3.9 Platform Integration Guide

Field names, hashing rules, consent string formats, and JSON for **`patientDetails`**, **`sessionDetails`**, and **`actionEvent`** are defined in the **Doceree Platform Integration Guide** from Doceree—not in this iOS guide. Swift examples in [§3.6](#36-data-attributes-api) show wiring only; if anything conflicts, **follow the Platform Guide**.

---

## 4. Ad slot integration (UI)

### 4.1 `DocereeAdView` basics

| Property / API | Purpose |
|----------------|---------|
| `DocereeAdView(with:and:adPosition:)` | Create slot; size string e.g. `"320 x 50"` |
| `docereeAdUnitId` | Dashboard ad unit ID |
| `rootViewController` | Host view controller |
| `delegate` | `DocereeAdViewDelegate` |
| `load(DocereeAdRequest())` | Fetch and render |

**`AdPosition`**

| Value | Behavior |
|-------|----------|
| `.top` | Pin to top of **safe area** (requires Auto Layout constraints) |
| `.bottom` | Pin above bottom **safe area** |
| `.custom` | Fixed frame or your own constraints (common for inline banners) |

On **iPhone**, `468 x 60` (full banner) and `728 x 90` (leaderboard) are rejected at load time.

### 4.2 Single ad slot (recommended pattern)

Uses `.custom` and safe-area-friendly layout (no deprecated `topLayoutGuide`):

```swift
import UIKit
import DocereeAdSdk

final class AdsViewController: UIViewController, DocereeAdViewDelegate {

    private var adView: DocereeAdView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let adView = DocereeAdView(with: "320 x 50", and: .zero, adPosition: .custom) else {
            return
        }
        self.adView = adView
        adView.docereeAdUnitId = "DOC_your_ad_unit_id"
        adView.rootViewController = self
        adView.delegate = self

        adView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adView)

        let size = adView.intrinsicContentSize
        NSLayoutConstraint.activate([
            adView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            adView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            adView.widthAnchor.constraint(equalToConstant: size.width),
            adView.heightAnchor.constraint(equalToConstant: size.height)
        ])

        adView.load(DocereeAdRequest())
    }

    func docereeAdViewDidReceiveAd(_ docereeAdView: DocereeAdView) {
        print("Ad loaded")
    }

    func docereeAdView(_ docereeAdView: DocereeAdView, didFailToReceiveAdWithError error: DocereeAdRequestError) {
        print("Ad failed: \(error)")
    }
}
```

### 4.3 Top / bottom pinned banner

```swift
private func pinBanner(_ banner: DocereeAdView, position: AdPosition) {
    banner.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(banner)

    switch position {
    case .top:
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    case .bottom:
        NSLayoutConstraint.activate([
            banner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    case .custom:
        break
    }
}
```

### 4.4 Multiple slots

Create **separate** `DocereeAdView` instances with distinct ad unit IDs and layouts (table cells, stack views, etc.). Each calls `load(DocereeAdRequest())` independently.

### 4.5 Delegate methods

All methods are optional via protocol extension defaults:

- `docereeAdViewDidReceiveAd(_:)`
- `docereeAdView(_:didFailToReceiveAdWithError:)`
- `docereeAdViewWillPresentScreen(_:)`
- `docereeAdViewWillDismissScreen(_:)`
- `docereeAdViewDidDismissScreen(_:)`
- `docereeAdViewWillLeaveApplication(_:)`

### 4.6 Handling ad load failures

Implement **`docereeAdView(_:didFailToReceiveAdWithError:)`**. Log **`error`** for support (`DocereeAdRequestError`).

| Error | What it usually means | What to do |
|-------|----------------------|------------|
| **`adNotFound`** | No ad for this request (common) | Hide the slot or retry later |
| **`invalidAppKey`** | App key not set | Call **`setApplicationKey`** before **`load`** |
| **`failedToCreateRequest`** | Network or request build issue | Check connectivity; retry **`load`** |
| **Other `DocereeAdRequestError` values** | Server, response, or configuration | Retry once; verify ad unit ID, **`login`**, and consent; contact Doceree if it persists |

**No delegate callback:** On iPhone, **`468 x 60`** and **`728 x 90`** are ignored inside **`load`** ([§4.1](#41-docereeadview-basics))—use a supported size instead.

---

## 5. Appendix: supported ad sizes

Pass these **exact** strings to `DocereeAdView(with:and:adPosition:)`:

| Size string | Typical name |
|-------------|----------------|
| `320 x 50` | Banner |
| `320 x 100` | Large banner |
| `300 x 250` | Medium rectangle |
| `300 x 50` | Small banner |
| `468 x 60` | Full banner (not on phone) |
| `728 x 90` | Leaderboard (not on phone) |

---

## Document history

| Version | SDK | Notes |
|---------|-----|--------|
| 2.2 | 6.3.2 | Publisher guide (checklist, ATT, lifecycle, errors); pod **6.3.2** |
| 2.1 | 6.3.1 | Integration checklist, ATT / Info.plist, identity lifecycle, Platform Guide pointer, ad error handling |
| 2.0 | 6.3.1 | CocoaPods `DocereeAdSdk`, builders, consent, no `sha256:` prefix, corrected ad API and layout |
| 1.x | Legacy | Superseded (incorrect pod name, legacy HCP API, GET `/v1/adrequest`) |

---

**Support:** [ios-sdk-new](https://github.com/doceree/ios-sdk-new) · Pod **`DocereeAdSdk`** **`6.3.2`**
