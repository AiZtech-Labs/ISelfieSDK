// swift-tools-version:5.9
//
// iSelfie SDK for iOS — distributed as a prebuilt binary (ISelfieSDK.xcframework), attached to
// each GitHub Release of this repository. Add it in Xcode: File → Add Package Dependencies →
// https://github.com/AiZtech-Labs/ISelfieSDK
import PackageDescription

let package = Package(
  name: "ISelfieSDK",
  platforms: [
    .iOS("15.1"),
  ],
  products: [
    .library(name: "ISelfieSDK", targets: ["ISelfieSDK"]),
  ],
  targets: [
    .binaryTarget(
      name: "ISelfieSDK",
      url: "https://github.com/AiZtech-Labs/ISelfieSDK/releases/download/1.0.0-rc.2/ISelfieSDK.xcframework.zip",
      checksum: "84ace869495a59d0824c299196935d8c118d23b10784f5e3ac3f517a8fb0d6f0"
    ),
  ]
)
