# ios-sdk-new

Doceree iOS SDK sources, podspec, and **`DocereeAdsSdk`** Xcode framework.

## Requirements

- Xcode 11 or higher
- iOS 15.0 or higher (see `DocereeAdSdk.podspec`)
- Create an account on Doceree

## Publishers: add the SDK with CocoaPods

In your app `Podfile`:

```ruby
pod 'DocereeAdSdk', '~> x.y.z'
```

Pick the version you ship; see release tags / podspec for current versions.

## Contributors: two workspaces

| What you are doing | Open | Run `pod install` |
|--------------------|------|-------------------|
| **SDK framework only** (build `DocereeAdsSdk`, run SDK tests, edit podspec) | **`DocereeAdsSdk.xcworkspace`** inside this folder | In **`ios-sdk-new`** (this folder) |
| **Sample app + SDK together** (parallel development with the parent repo) | Parent repo **`DocereeiOSMainNew.xcworkspace`** | At **repository root** *and* in **`ios-sdk-new`** when you touch the SDK’s Pods integration |

- **`ios-sdk-new/DocereeAdsSdk.xcworkspace`** — includes `DocereeAdsSdk.xcodeproj` and this folder’s **`Pods`** project. Use this when you only work on the SDK.
- **Parent `DocereeiOSMainNew`** — links the **`DocereeAdsSdk`** subproject **and** uses the root **`Podfile`** (local path to this pod). That is the flow for iterating on both the demo UI and SDK sources; see the parent **`README.md`**.

The demo app imports **`DocereeAdsSdk`** (framework). Integrators who use CocoaPods alone import **`DocereeAdSdk`** (pod module name).

## Signpost profiling (Instruments)

Use this when measuring SDK runtime behavior.

1. Run the host app (or sample app) with this SDK linked.
2. For `Release` profiling, set `DocereeMobileAds.isSignpostEnabled = true` before SDK network/ad calls.
3. Record with Instruments using a template that includes **os_signpost** / **Points of Interest**.
4. Filter by `doceree.` to focus on SDK events.

Current signpost names:

- `doceree.execute_app_config`
- `doceree.config_http`
- `doceree.config_decode`
- `doceree.request_ad`
- `doceree.request_ad_http`
- `doceree.request_ad_decode`
- `doceree.ad_view_load`
- `doceree.beacon_send`

Notes:

- You will see the **host app process** in Instruments, not a separate SDK process (expected for embedded frameworks).
- Durations are wall-clock time and include network latency.

## Quick verify commands

From `ios-sdk-new`:

```bash
pod install
xcodebuild test -workspace DocereeAdsSdk.xcworkspace -scheme DocereeAdsSdk -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Troubleshooting notes

- **`Framework 'Pods_DocereeAdsSdkTests' not found`**
  - Run `pod install` in `ios-sdk-new`.
  - Keep the `post_integrate` block in `ios-sdk-new/Podfile` (it strips injected `Pods_*` umbrella framework links that can break this workspace setup).

- **`tasks in 'Copy Headers' are delayed by unsandboxed script phases`**
  - Informational warning from Xcode script phase sandboxing checks.
  - Safe to ignore for local development unless you explicitly enforce script sandboxing policy.

- **KetchSDK warning about `index.html` processing**
  - This comes from a third-party pod target (`KetchSDK`).
  - Do not patch vendor sources in this repo for that warning; treat as non-blocking unless the vendor ships a fix.

## License

This code is distributed under the terms and conditions of the [MIT license](https://github.com/doceree/ios-sdk/blob/master/MIT%20License).
