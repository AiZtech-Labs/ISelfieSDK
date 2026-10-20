# iSelfie SDK

Add a heart health check to your app. The iSelfie SDK opens the front camera, guides the user
through a short face scan and returns their vitals: **heart rate, blood pressure, SpO2, heart
rate variability and respiratory rate**. The vitals are computed by the iSelfie service; your
plan limits and test history are managed in the
[iSelfie Developer Console](https://developer.iselfie.ai/).

| Platform | Latest version | Install |
|---|---|---|
| iOS | 0.9.1 | Swift Package Manager — this repository |
| Android | 0.9.0 | Maven Central — `ai.iselfie:iselfie-sdk` |

Both platforms have the same features and API; each has its own version number.

> **Wellness, not medical.** The results are general wellness information. The SDK is not a
> medical device and does not provide medical advice, diagnosis or treatment. Don't present your
> app or its results as such (see the [license](#license), section 6).

## Contents

- [Requirements](#requirements)
- [Install](#install)
- [Before you start: access tokens](#before-you-start-access-tokens)
- [Initialize](#initialize)
- [Start the test](#start-the-test)
- [Options](#options)
- [Styles](#styles)
- [Instruction page](#instruction-page)
- [Status updates](#status-updates)
- [Result](#result)
- [Errors](#errors)
- [Webhook](#webhook)
- [Privacy](#privacy)
- [Logs](#logs)
- [Checklist](#checklist)
- [License](#license)
- [Support](#support)
- [Changelog](#changelog)

## Requirements

| | iOS | Android |
|---|---|---|
| OS | iOS 15.1 or later | Android 7.0 (API 24) or later |
| Device | An iPhone with a front camera | A phone or tablet with a front camera |
| Tools | Xcode 26 or later | `compileSdk` 35 or later, Android Gradle Plugin 8.1.1 or later, Kotlin 2.0 or later (Kotlin apps) |

- **Scan on a real device.** The iOS Simulator has no camera, and the face model doesn't run on
  the Android emulator on Apple Silicon Macs. Everything else works there.
- Your **organization ID** and **API key** from the
  [iSelfie Developer Console](https://developer.iselfie.ai/) (Settings). No account yet? Write
  to [hi@iselfie.ai](mailto:hi@iselfie.ai).

## Install

### iOS

In Xcode: **File → Add Package Dependencies…**, enter `https://github.com/AiZtech-Labs/ISelfieSDK`
and add the **ISelfieSDK** library to your app target. Or, in a `Package.swift`:

```swift
.package(url: "https://github.com/AiZtech-Labs/ISelfieSDK", exact: "0.9.1")
```

Add the camera usage text to your app's `Info.plist` (iOS requires it):

```xml
<key>NSCameraUsageDescription</key>
<string>The camera is used to measure your heart rate from your face.</string>
```

### Android

In your app's `build.gradle.kts` (the SDK is on Maven Central):

```kotlin
dependencies {
  implementation("ai.iselfie:iselfie-sdk:0.9.0")
}
```

The SDK declares the `CAMERA` and `INTERNET` permissions and ships its own R8/ProGuard rules;
nothing else to add.

On both platforms the SDK asks for camera permission itself when a test starts.

## Before you start: access tokens

The SDK authenticates with short-lived **access tokens**. Your **backend** mints them with your
API key; your app only ever receives the token.

> **Never put your API key in the app.** Anything shipped in an app can be extracted.

From your backend:

```bash
curl -X POST https://consumer-api.iselfie.ai/sdk/central/access-token \
  -H "Content-Type: application/json" \
  -d '{"organizationId": "<ORGANIZATION_ID>", "apikey": "<API_KEY>"}'
# → { "access_token": "eyJ..." }
```

- A token is valid for **1 hour**. The SDK renews it automatically while the test screen is
  open, for up to **2 hours** after it was minted.
- Get a new token each time the user opens your test screen.

## Initialize

Call `initialize` with a fresh token when the user opens your test screen.

**iOS**

```swift
import ISelfieSDK

ISelfieCardio.initialize(
  accessToken: token,
  organizationId: "<ORGANIZATION_ID>",
  appUserId: currentUser.internalId    // optional
) { availability in
  if availability.isAvailable {
    // enable your "Start test" button
  } else {
    // availability.error?.code — e.g. .trialUsageLimitExceeded; see Errors
  }
}
```

**Android**

```kotlin
import ai.iselfie.sdk.cardio.ISelfieCardio

ISelfieCardio.initialize(
  context = this,
  accessToken = token,
  organizationId = "<ORGANIZATION_ID>",
  appUserId = currentUser.internalId,  // optional
) { availability ->
  if (availability.isAvailable) {
    // enable your "Start test" button
  } else {
    // availability.error?.code — e.g. TRIAL_USAGE_LIMIT_EXCEEDED; see Errors
  }
}
```

| Parameter | Description |
|---|---|
| `accessToken` | The token from your backend. |
| `organizationId` | Your organization ID. |
| `appUserId` | Optional. Your own ID for the user, stored with each test and sent in the webhook. Use an **opaque internal ID** — never an email, phone number or national ID. |
| completion | Called on the main thread: `isAvailable`, and `error` when a test can't start. |

`initialize` checks your token and your plan, so you can show the right state on your screen
from the start.

## Start the test

The ready-made test includes the **"Before you start"** page (tips, your organization's name and
logo), the scan, an optional result page, and a failure screen with "Restart test".

**iOS**

```swift
import ISelfieSDK

var options = CardioTestOptions()
options.language = .spanish

let test = ISelfieCardioTestViewController(options: options)
test.onCompleted = { result in
  // the vitals — see Result
}
test.onFailed = { failure in
  switch failure.code {
  case .trialUsageLimitExceeded, .subscriptionUsageLimitExceeded:
    showMessage("No tests left this month. Please contact the clinic.")
  case .trialExpired, .noActiveSubscription, .productNotEntitled:
    showMessage("Heart tests aren't available right now.")
  default:
    break   // the user closed the test, or saw the failure in it
  }
}
test.start(from: self)
```

**Android**

```kotlin
import ai.iselfie.sdk.cardio.CardioError
import ai.iselfie.sdk.cardio.CardioLanguage
import ai.iselfie.sdk.cardio.CardioTestOptions
import ai.iselfie.sdk.cardio.ISelfieCardioTest

val options = CardioTestOptions().apply {
  language = CardioLanguage.SPANISH
}

val test = ISelfieCardioTest(options)
test.onCompleted = { result ->
  // the vitals — see Result
}
test.onFailed = { failure ->
  when (failure.code) {
    CardioError.Code.TRIAL_USAGE_LIMIT_EXCEEDED, CardioError.Code.SUBSCRIPTION_USAGE_LIMIT_EXCEEDED ->
      showMessage("No tests left this month. Please contact the clinic.")
    CardioError.Code.TRIAL_EXPIRED, CardioError.Code.NO_ACTIVE_SUBSCRIPTION, CardioError.Code.PRODUCT_NOT_ENTITLED ->
      showMessage("Heart tests aren't available right now.")
    else -> Unit   // the user closed the test, or saw the failure in it
  }
}
test.start(this)   // an Activity
```

Starting checks your plan first:

- **When a test is allowed**, the test opens full screen and closes itself before calling
  `onCompleted` or `onFailed`.
- **When it isn't** (no tests left, trial ended…), **nothing is shown**: `onFailed` receives
  `unavailable(error)` with the reason, and your app decides what to tell the user.

The check takes well under a second. Show that something is happening (e.g. a disabled button
with "Checking…") until `onFailed` or the first status update arrives.

On Android the callbacks live in memory: if the system kills your app's process while the test is
in the background, the test closes without calling them. Use the [webhook](#webhook) for the
result of record.

## Options

The same options on both platforms (`CardioTestOptions`). Enum values are `.camelCase` on iOS and
`UPPER_CASE` on Android (`.spanish` / `CardioLanguage.SPANISH`).

| Option | Default | Description |
|---|---|---|
| `language` | English | English, Spanish or Arabic (right to left). Screens and voice guidance. |
| `style` | system | Colors and font — see [Styles](#styles). |
| `showLanguageSelector` | `true` | A language picker on the instructions page. Turn it off when your app sets `language`. |
| `instructionPage` | shown | The "Before you start" page — see [Instruction page](#instruction-page). |
| `displayResults` | `false` | Shows a result page (each metric, its normal range, a wellness notice). `onCompleted` is called when the user closes it. |
| `timeZone` | device's | Time zone of the date on the result page. |
| `enableResultSharing` | `false` | A share button on the result page: after a privacy notice, an image of the result in the share sheet. Needs `displayResults`. |
| `disableAudio` | `false` | No voice guidance; the countdown still shows on screen. |
| `disableMotionDetection` | `false` | Head movement no longer lowers the quality or asks to hold still. |
| `disableLightCheck` | `false` | A dark scene no longer counts as a bad frame. |
| `disableDistanceCheck` | `false` | Being too far or too close no longer counts as a bad frame. |
| `terminateTestIfConditionPersisted` | `true` | Ends the test when the face stays unusable for `testTerminationTimeOut` seconds. `false` keeps waiting. |
| `testTerminationTimeOut` | `7` | Seconds before the test ends (see above). |
| `progressBarPosition` | top | Top or bottom of the camera view. |
| `enableMobileCameraSwap` | `false` | A button to switch between the front and rear camera. |

## Styles

Start from the system style (follows the device's light/dark setting), dark or light, and change
what you need.

**iOS**

```swift
var style = CardioStyle.light
style.buttonColor = UIColor(named: "Brand")!
style.fontFace = "Avenir Next"
options.style = style
```

**Android**

```kotlin
options.style = CardioStyle.LIGHT.copy(
  buttonColor = ContextCompat.getColor(context, R.color.brand),
  typeface = ResourcesCompat.getFont(context, R.font.brand),
)
```

| Property | Description |
|---|---|
| `pageBackgroundColors` | One color, or two or more for a top-to-bottom gradient. |
| `cardBackgroundColor` | Background of the cards. |
| `cardHeaderBackgroundColor` | Background of the header bar. |
| `primaryTextColor` / `secondaryTextColor` | Text colors. |
| `buttonColor` / `buttonTextColor` | Main button. |
| `iconColor` | Icons and checkboxes. |
| `fontFace` (iOS) / `typeface` (Android) | Your font; `nil` / `null` for the system font. |

## Instruction page

The "Before you start" page is shown by default; some jurisdictions require it.

```swift
// iOS
options.instructionPage.hidden = true                 // open straight on the scan
options.instructionPage.allowsDontShowAgain = true    // offer "Don't show this again"
CardioInstructionPage.resetDontShowAgain()            // show it again (e.g. from your settings)
```

```kotlin
// Android
options.instructionPage.hidden = true
options.instructionPage.allowsDontShowAgain = true
CardioInstructionPage.resetDontShowAgain(context)
```

Your own instructions, per language (shown in the test's language, then English, then the first
one given; HTML is shown without scripts):

```swift
// iOS
options.instructionPage.content = CardioInstructionContent(translations: [
  .init(language: .english, header: "Before your check", body: .items([
    .init(title: "Find a bright place", subtitle: "Face a window or a white light"),
  ])),
  .init(language: .spanish, header: "Antes de comenzar", body: .html("<p>…</p>")),
])
```

```kotlin
// Android
options.instructionPage.content = CardioInstructionContent(listOf(
  CardioInstructionContent.Translation(CardioLanguage.ENGLISH, "Before your check",
    CardioInstructionContent.Body.Items(listOf(
      CardioInstructionContent.Item("Find a bright place", "Face a window or a white light"),
    ))),
  CardioInstructionContent.Translation(CardioLanguage.SPANISH, "Antes de comenzar",
    CardioInstructionContent.Body.Html("<p>…</p>")),
))
```

## Status updates

`onStatus` reports each step of the test, e.g. for analytics:

| Status (iOS / Android) | When |
|---|---|
| `.instructions` / `Instructions` | The "Before you start" page is showing. |
| `.started` / `Started` | The user started the test. |
| `.inProgress` / `InProgress` | The camera is on and the scan is running. |
| `.processing` / `Processing` | The scan is done; the vitals are being computed. |
| `.completed` / `Completed` | The vitals are back. |
| `.failed(failure)` / `Failed(failure)` | The test failed; the user sees why, with the option to restart. |
| `.cancelled` / `Cancelled` | The user closed the test, or went back from the scan. |

## Result

The same fields on both platforms:

| Field | |
|---|---|
| `heartRate` | Beats per minute. |
| `bloodPressure` | Systolic, diastolic and a label. |
| `spo2` | %. |
| `hrv` | Milliseconds. |
| `respiratoryRate` | Breaths per minute. |
| `testId` | The test's ID (also in the webhook). |
| `appUserId` | The `appUserId` the test was recorded with. |
| `createdAt` | When the test was recorded. |

**Every metric is optional.** Your plan decides which metrics you receive, and a single
measurement can also be missing. Show what is there; don't treat a missing value as zero.

## Errors

`onFailed` receives a `CardioScanFailure`. `failure.code` gives the error code when there is
one, and `failure.displayMessage(language)` a ready-to-show message.

| Failure (iOS / Android) | Meaning |
|---|---|
| `.unavailable(error)` / `Unavailable(error)` | The plan or the token doesn't allow a test. Nothing was shown to the user. |
| `.resultError(error)` / `ResultError(error)` | The scan finished but no vitals came back (network, tests used up meanwhile…). |
| `.cameraPermissionDenied` / `CameraPermissionDenied` | The user didn't allow the camera. |
| `.tooManyInvalidFrames` / `TooManyInvalidFrames` | The face couldn't be measured for too long (left the frame, too dark…). |
| `.interrupted` / `Interrupted` | The camera was interrupted for too long (a call, the app in the background). |
| `.cancelled` / `Cancelled` | The user closed the test. |

| Code | iOS / Android | Meaning |
|---|---|---|
| AIZERR001 | `.trialExpired` / `TRIAL_EXPIRED` | The free trial has ended. |
| AIZERR002 | `.trialUsageLimitExceeded` / `TRIAL_USAGE_LIMIT_EXCEEDED` | All the tests in the plan were used. |
| AIZERR003 | `.subscriptionUsageLimitExceeded` / `SUBSCRIPTION_USAGE_LIMIT_EXCEEDED` | All the tests in the subscription were used. |
| AIZERR004 | `.noActiveSubscription` / `NO_ACTIVE_SUBSCRIPTION` | No active subscription. |
| AIZERR007 | `.invalidOrganizationId` / `INVALID_ORGANIZATION_ID` | Unknown organization ID. |
| AIZERR008 | `.invalidAccessToken` / `INVALID_ACCESS_TOKEN` | The token is invalid or can no longer be renewed. |
| AIZERR010 | `.productNotEntitled` / `PRODUCT_NOT_ENTITLED` | The heart health test isn't in the plan. |
| AIZERR011 | `.testCancelled` / `TEST_CANCELLED` | The test was cancelled. |
| AIZERR012 | `.serviceUnreachable` / `SERVICE_UNREACHABLE` | The iSelfie service couldn't be reached. |

**Expired token:** when the token can no longer be renewed (the screen stayed open for over
2 hours, the app sat in the background, the device was offline), the failure has the code
`invalidAccessToken`. Get a new token from your backend and call `initialize` again.

## Webhook

Each completed test is also sent to your organization's **webhook URL**
([Developer Console](https://developer.iselfie.ai/)) with the vitals, the test ID and your
`appUserId`. It reaches your backend even if the app closes right after the test, so use it as
the source of truth for results. Configure the webhook's authentication in the Developer Console
and verify it on every request.

## Privacy

- The SDK sends a color signal measured from the face, and the face's position — never an image
  or a video — plus your `appUserId`. The vitals are computed by the iSelfie service.
- **iOS:** the SDK includes its privacy manifest; Xcode adds it to your app's privacy report. In
  your App Store privacy details, declare **Health & Fitness** and, if you pass `appUserId`,
  **User ID** — linked to the user, for app functionality, not used for tracking.
- **Android:** in your Google Play Data safety form, declare **Health info** and, if you pass
  `appUserId`, **User IDs** — collected for app functionality, not shared, encrypted in transit.
- All traffic uses HTTPS.

## Logs

Off by default. To see the SDK's requests while you integrate:

```swift
ISelfieCardio.logLevel = .basic                          // iOS — Xcode console, filter "ai.iselfie.sdk"
```

```kotlin
ISelfieCardio.logLevel = ISelfieCardio.LogLevel.BASIC    // Android — Logcat, tag "ISelfieSDK"
```

One line per request — method, URL, status and duration. No health data and no user data, so
it's safe to leave on.

## Checklist

- [ ] The API key stays on your backend; the app receives tokens from your backend.
- [ ] iOS: `NSCameraUsageDescription` is in `Info.plist`.
- [ ] `initialize` runs each time the test screen opens, with a fresh token.
- [ ] `onFailed` handles the plan errors with your own message, and `invalidAccessToken` by
      initializing again.
- [ ] Results are shown with every metric optional, as wellness information.
- [ ] `appUserId` is an opaque internal ID.
- [ ] Your webhook endpoint verifies the request authentication.
- [ ] Your store privacy details declare health data (and the user ID if you pass it).

## License

The iSelfie SDK is proprietary software of AiZtech Labs Inc., licensed under the
[iSelfie SDK License Agreement](https://www.iselfie.ai/sdk-license) (also in [LICENSE](LICENSE)).
It works only with an iSelfie organization account that has an active plan or free trial.
Third-party components and their licenses are listed in
[THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES.md).

## Support

Questions about the SDK, your plan or your account: **hi@iselfie.ai**.

## Changelog

### Android 0.9.0

First release of the iSelfie SDK for Android, on Maven Central: the same API, options, screens
and texts as the iOS SDK, under the
[iSelfie SDK License Agreement](https://www.iselfie.ai/sdk-license).

### iOS 0.9.1

License change only, no code changes (same binary as 0.9.0): the SDK is now distributed under the
proprietary [iSelfie SDK License Agreement](https://www.iselfie.ai/sdk-license), which replaces the
MIT License, with its [third-party notices](THIRD_PARTY_NOTICES.md).

### iOS 0.9.0

First release (pre-release) of the iSelfie SDK for iOS: the ready-made heart health test
(instructions, scan, result page, result sharing), heart rate, blood pressure, SpO2, HRV and
respiratory rate, English, Spanish and Arabic, light, dark and system styles.
