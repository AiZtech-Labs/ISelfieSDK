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
      url: "https://github.com/AiZtech-Labs/ISelfieSDK/releases/download/0.9.0/ISelfieSDK.xcframework.zip",
      checksum: "473a410219f41d59e10173ff3e35625526a3cf88b217d852929b7fa1f9ddb4a0"
    ),
  ]
)
