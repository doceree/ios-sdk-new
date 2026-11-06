# DocereeAdSdk 6.3.2

## Summary

Patch release aligning the shipped CocoaPods version with the publisher **Native Integration Guide (v2.2)** and internal test/sample hashing conventions.

## Publishers

- Pin: `pod 'DocereeAdSdk', '6.3.2'`
- Documentation: [Doceree_iOS_SDK_Integration_Guide.md](./Doceree_iOS_SDK_Integration_Guide.md)
- **Hashed fields:** lowercase SHA-256 **hex** (64 characters), **no** `sha256:` prefix; SDK does not hash on your behalf.

## Changes since 6.3.1

- Integration guide v2.2 (setup checklist, ATT, identity lifecycle, ad errors, Platform Guide pointer).
- Unit tests use platform-style hex digests (no `sha256:` prefix in fixtures).
- Sample app hashing helpers aligned with hex-only publisher format (legacy prefix stripped when pasting old samples).

## Upgrade

1. Update Podfile to `'6.3.2'` and run `pod install`.
2. Ensure pre-hashed identity fields match the Platform Integration Guide (hex, not Base64).
3. No API break expected for standard `login`, `setConsent`, and `DocereeAdView` integrations on 6.3.1.
