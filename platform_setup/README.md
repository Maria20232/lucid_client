# Platform setup for the existing Flutter project

Chrome photo selection needs no Android changes. Start there while checking the
backend contract. Native camera and local HTTP networking need platform review.

## Android

The selected image-picker version supports Android SDK 24+. Check your existing
`android/app/build.gradle` or `build.gradle.kts` minimum SDK. Do not reduce a higher
minimum already required by your project.

Ensure `android/app/src/main/AndroidManifest.xml` contains this as a direct child
of `<manifest>`, outside `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

To use the development backend over HTTP, the supplied `android/app/src/debug/`
and `android/app/src/profile/` files show the required overlay. Merge their
permission/application attributes into the corresponding files in your actual
project. Retain any other existing entries. Do not replace the main manifest
with these small overlay files.

The relevant application setting is:

```xml
<application android:usesCleartextTraffic="true" />
```

Keep that development allowance out of the release configuration. If your app
already sets `android:networkSecurityConfig`, configure the development allowance
in the corresponding debug network-security resource: that configuration may
take precedence over `usesCleartextTraffic`.

The image-picker plugin uses Android system capture/picker intents and does not
require broad storage permissions or a custom camera permission for this flow.
Startup recovery for an interrupted Android picker is included in the welcome
screen. Retest it on a real device with the actual manifest/launch configuration.

## iOS

The selected picker supports iOS 13+. Add meaningful `NSCameraUsageDescription`
and `NSPhotoLibraryUsageDescription` entries to `ios/Runner/Info.plist` before
using native capture/selection. Example values:

```xml
<key>NSCameraUsageDescription</key>
<string>Lucid uses the camera to photograph food ingredient labels.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Lucid lets you select a food-label photo for ingredient recognition.</string>
```

Microphone permission is not needed for this still-photo flow. iOS development
access to an HTTP LAN server can also require platform-specific network/privacy
configuration; use HTTPS for a deployed service. iOS platform files were not
provided and have not been modified or tested here.

## Desktop

The current UI enables camera capture only on Android/iOS. Desktop and Chrome
use file/photo selection. Native desktop platform builds and entitlement settings
still require checks on their respective operating systems.
