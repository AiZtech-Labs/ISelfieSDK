# iSelfie SDK

Add a heart health check to your app. The iSelfie SDK opens the front camera, guides the user
through a short face scan and returns their vitals: **heart rate, blood pressure, SpO2, heart
rate variability and respiratory rate**. The vitals are computed by the iSelfie service; your
plan limits and test history are managed in the
[iSelfie Developer Console](https://developer.iselfie.ai/).

| Platform | Status |
|---|---|
| iOS | Available — Swift Package Manager |
| Android | Coming soon |

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
- [Changelog](#changelog)

## Requirements

- iOS 15.1 or later, on an iPhone with a front camera.
- Xcode 26 or later.
- Your **organization ID** and **API key** from the
  [iSelfie Developer Console](https://developer.iselfie.ai/) (Settings).

## Install

In Xcode: **File → Add Package Dependencies…**, enter:

```
https://github.com/AiZtech-Labs/ISelfieSDK
```

and add the **ISelfieSDK** library to your app target. With a `Package.swift`:

```swift
.package(url: "https://github.com/AiZtech-Labs/ISelfieSDK", exact: "0.9.0")
```

Then declare the camera usage text in your app's `Info.plist` (iOS requires it to open the
camera):

```xml
<key>NSCameraUsageDescription</key>
<string>The camera is used to measure your heart rate from your face.</string>
```

The SDK asks for camera permission itself when a test starts.

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

Call `initialize` with a fresh token when the user opens your test screen:

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

| Parameter | Description |
|---|---|
| `accessToken` | The token from your backend. |
| `organizationId` | Your organization ID. |
| `appUserId` | Optional. Your own ID for the user, stored with each test and sent in the webhook. Use an **opaque internal ID** — never an email, phone number or national ID. |
| `completion` | Called on the main thread with the result: `isAvailable`, and `error` when a test can't start. |

`initialize` checks your token and your plan, so you can show the right state on your screen
from the start.

## Start the test

The ready-made test includes the **"Before you start"** page (tips, your organization's name and
logo), the scan, an optional result page, and a failure screen with "Restart test".

```swift
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

`start(from:)` checks your plan first:

- **When a test is allowed**, it presents the test full screen. The test closes itself before
  calling `onCompleted` or `onFailed`.
- **When it isn't** (no tests left, trial ended…), **nothing is shown**: `onFailed` receives
  `.unavailable(error)` with the reason, and your app decides what to tell the user.

The check takes well under a second. Show that something is happening (e.g. a disabled button
with "Checking…") until `onFailed` or the first status update arrives.

## Options

All options of `CardioTestOptions`:

| Option | Default | Description |
|---|---|---|
| `language` | `.english` | `.english`, `.spanish` or `.arabic` (right to left). Screens and voice guidance. |
| `style` | `.system` | Colors and font — see [Styles](#styles). |
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
| `progressBarPosition` | `.top` | `.top` or `.bottom` of the camera view. |
| `enableMobileCameraSwap` | `false` | A button to switch between the front and rear camera. |

## Styles

Start from `.system` (follows the device's light/dark setting), `.dark` or `.light`, and change
what you need:

```swift
var style = CardioStyle.light
style.buttonColor = UIColor(named: "Brand")!
style.fontFace = "Avenir Next"
options.style = style
```

| Property | Description |
|---|---|
| `pageBackgroundColors` | One color, or two or more for a top-to-bottom gradient. |
| `cardBackgroundColor` | Background of the cards. |
| `cardHeaderBackgroundColor` | Background of the header bar. |
| `primaryTextColor` / `secondaryTextColor` | Text colors. |
| `buttonColor` / `buttonTextColor` | Main button. |
| `iconColor` | Icons and checkboxes. |
| `fontFace` | A font family available to your app; `nil` for the system font. |
| `interfaceStyle` | `.dark`, `.light` or `.unspecified` (follows the device) — for the status bar and system menus. |

## Instruction page

The "Before you start" page is shown by default; some jurisdictions require it.

```swift
// Hide it — the test opens straight on the scan.
options.instructionPage.hidden = true

// Or let the user skip it next time with "Don't show this again".
options.instructionPage.allowsDontShowAgain = true
CardioInstructionPage.resetDontShowAgain()   // show it again (e.g. from your settings)
```

Use your own instructions, per language:

```swift
options.instructionPage.content = CardioInstructionContent(translations: [
  .init(language: .english, header: "Before your check", body: .items([
    .init(icon: URL(string: "https://example.com/light.png"), title: "Find a bright place",
          subtitle: "Face a window or a white light"),
    .init(title: "Sit still", subtitle: "Rest for a minute before starting"),
  ])),
  .init(language: .spanish, header: "Antes de comenzar", body: .html("<p>…</p>")),
])
```

The test shows the translation for its language, then English, then the first one given.
`.html` content is shown without scripts; links open in the browser.

## Status updates

`onStatus` reports each step of the test:

| Status | When |
|---|---|
| `.instructions` | The "Before you start" page is showing. |
| `.started` | The user started the test. |
| `.inProgress` | The camera is on and the scan is running. |
| `.processing` | The scan is done; the vitals are being computed. |
| `.completed` | The vitals are back. |
| `.failed(failure)` | The test failed; the user sees why, with the option to restart. |
| `.cancelled` | The user closed the test, or went back from the scan. |

```swift
test.onStatus = { status in analytics.track("cardio_test", status) }
```

## Result

```swift
test.onCompleted = { result in
  result.heartRate          // Int?  beats per minute
  result.bloodPressure      // systolic, diastolic, label — optional
  result.spo2               // Int?  %
  result.hrv                // Int?  ms
  result.respiratoryRate    // Int?  breaths per minute
  result.testId             // the test's ID (also in the webhook)
  result.appUserId          // the appUserId the test was recorded with
  result.createdAt          // Date?
}
```

**Every metric is optional.** Your plan decides which metrics you receive, and a single
measurement can also be missing. Show what is there; don't treat a missing value as zero.

## Errors

`onFailed` receives a `CardioScanFailure`. `failure.code` gives the error code when there is
one, and `failure.displayMessage(language:)` a ready-to-show message.

| Failure | Meaning |
|---|---|
| `.unavailable(error)` | The plan or the token doesn't allow a test. Nothing was shown to the user. |
| `.resultError(error)` | The scan finished but no vitals came back (network, tests used up meanwhile…). |
| `.cameraPermissionDenied` | The user didn't allow the camera. |
| `.tooManyInvalidFrames` | The face couldn't be measured for too long (left the frame, too dark…). |
| `.interrupted` | The camera was interrupted for too long (a call, the app in the background). |
| `.cancelled` | The user closed the test. |

| Code | `CardioError.Code` | Meaning |
|---|---|---|
| AIZERR001 | `.trialExpired` | The free trial has ended. |
| AIZERR002 | `.trialUsageLimitExceeded` | All the tests in the plan were used. |
| AIZERR003 | `.subscriptionUsageLimitExceeded` | All the tests in the subscription were used. |
| AIZERR004 | `.noActiveSubscription` | No active subscription. |
| AIZERR007 | `.invalidOrganizationId` | Unknown organization ID. |
| AIZERR008 | `.invalidAccessToken` | The token is invalid or can no longer be renewed. |
| AIZERR010 | `.productNotEntitled` | The heart health test isn't in the plan. |
| AIZERR011 | `.testCancelled` | The test was cancelled. |
| AIZERR012 | `.serviceUnreachable` | The iSelfie service couldn't be reached. |

**Expired token:** when the token can no longer be renewed (the screen stayed open for over
2 hours, the app sat in the background, the device was offline), the failure has code
`.invalidAccessToken`. Get a new token from your backend and call `initialize` again.

## Webhook

Each completed test is also sent to your organization's **webhook URL** ([Developer Console](https://developer.iselfie.ai/)) with
the vitals, the test ID and your `appUserId`. It reaches your backend even if the app closes
right after the test, so use it as the source of truth for results. Configure the webhook's
authentication in the Developer Console and verify it on every request.

## Privacy

- The SDK sends a color signal measured from the face, and the face's position — never an image
  or a video — plus your `appUserId`. The vitals are computed by the iSelfie service.
- The SDK includes its privacy manifest; Xcode adds it to your app's privacy report. In your App
  Store privacy details, declare **Health & Fitness** data and, if you pass `appUserId`,
  **User ID** — linked to the user, for app functionality, not used for tracking.
- All traffic uses HTTPS.

## Logs

Off by default. To see the SDK's requests in the Xcode console while you integrate:

```swift
ISelfieCardio.logLevel = .basic
```

One line per request — method, URL, status and duration. No health data and no user data, so
it's safe to leave on. Filter the Xcode console by `ai.iselfie.sdk`.

## Checklist

- [ ] The API key stays on your backend; the app receives tokens from your backend.
- [ ] `NSCameraUsageDescription` is in `Info.plist`.
- [ ] `initialize` runs each time the test screen opens, with a fresh token.
- [ ] `onFailed` handles the plan errors with your own message, and `.invalidAccessToken` by
      initializing again.
- [ ] Results are shown with every metric optional.
- [ ] `appUserId` is an opaque internal ID.
- [ ] Your webhook endpoint verifies the request authentication.
- [ ] Your App Store privacy details declare Health & Fitness (and User ID if you pass it).

## Changelog

### 0.9.0

First release (pre-release) of the iSelfie SDK for iOS: the ready-made heart health test
(instructions, scan, result page, result sharing), heart rate, blood pressure, SpO2, HRV and
respiratory rate, English, Spanish and Arabic, light, dark and system styles.
