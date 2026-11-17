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
      url: "https://github.com/AiZtech-Labs/ISelfieSDK/releases/download/1.0.0-rc.1/ISelfieSDK.xcframework.zip",
      checksum: "2b176ff93172e713f86e1742859cf18f0e3d1a72f909710960eb545f6aee73dd"
    ),
  ]
)
