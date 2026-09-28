<p align="center">
  <img src="https://media.onesignal.com/cms/Website%20Layout/logo-red.svg"/>
</p>

### OneSignal iOS SDK
[![CocoaPods](https://img.shields.io/cocoapods/v/OneSignal.svg)](https://cocoapods.org/pods/OneSignal) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage) [![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg)](https://goo.gl/E01ufX) [![Build Status](https://travis-ci.org/OneSignal/OneSignal-iOS-SDK.svg?branch=master)](https://travis-ci.org/OneSignal/OneSignal-iOS-SDK)

---

#### Fork: no auto init (`5.7.0-noautoinit.*`)

This fork adds a persisted native gate so the SDK does not self-initialize from a cached app id
unless the host allowed it (`OneSignal.initialize` sets it to allowed). It is consumed via CocoaPods
`:git`/`:tag`, and `OneSignalFramework` is compiled from source.

Privacy manifest: the source-built `OneSignalFramework` does **not** ship its
`PrivacyInfo.xcprivacy` as a resource bundle (that would add a "[CP] Copy Pods Resources" phase
that fails under user script sandboxing). The prebuilt upstream binaries keep their embedded
manifests; host apps must merge the entries of `iOS_SDK/OneSignalSDK/Source/PrivacyInfo.xcprivacy`
into their own `PrivacyInfo.xcprivacy`.

Closing the gate (`setAutoInitAllowed:NO`) also silences an SDK already running in the process and
the notification service extension: privacy consent is required (written directly, even when
`ios_params` said it isn't) and withdrawn, so every non-GET request (sessions, user updates, receive
receipts) is blocked, and receive receipts are turned off. While the gate is closed `ios_params`
cannot re-enable receipts or drop the consent requirement. `initialize` plus
`setConsentGiven:YES` resume it.

Upgrade behaviour: the gate defaults to **not allowed**, so after upgrading to this fork a device
that should stay on OneSignal does not start the SDK (and gets no OneSignal pushes that need it)
until the app is opened and calls `OneSignal.initialize`, which persists the gate as allowed. This is
intended: devices whose app never runs again stop counting as MAU.

---

#### Migrating from v4 or earlier?

See our [Migration Guide](MIGRATION_GUIDE.md) for detailed instructions on upgrading to v5.x.x.

---

[OneSignal](https://www.onesignal.com) is a free email, sms, push notification, and in-app message service for mobile apps. This plugin makes it easy to integrate your native iOS app with OneSignal.

<p align="center"><img src="https://github.com/user-attachments/assets/8e75f4c6-9ac5-468c-b47b-a111eedb628f" width="400" alt="iOS Notification"></p>

#### Installation
See OneSignal's [iOS Native SDK Setup Guide](https://documentation.onesignal.com/docs/ios-sdk-setup) for documentation.

#### API
See OneSignal's [Mobile SDK reference](https://documentation.onesignal.com/docs/en/mobile-sdk-reference) page for a list of all available methods.

#### Change Log
See this repository's [release tags](https://github.com/OneSignal/OneSignal-iOS-SDK/releases) for a complete change log of every released version.

#### Support
Please visit this repository's [Github issue tracker](https://github.com/OneSignal/OneSignal-iOS-SDK/issues) for feature requests and bug reports related specifically to the SDK.
For account issues and support please contact OneSignal support from the [OneSignal.com](https://onesignal.com) dashboard.

#### Supports:
* Swift and Objective-C Projects
* Supports iOS 15 to iOS 26
