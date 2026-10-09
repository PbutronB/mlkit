// swift-tools-version:5.7
// Swift Package for Google ML Kit 3.2.0 (the CocoaPods `GoogleMLKit/*` 3.2.0 subspecs):
// FaceDetection, ImageLabeling, ObjectDetection and TextRecognition (Latin).
//
// Add the package, add the `MLKit` product to the app target, `import MLKit`. No linker flags,
// no resources to copy: the binaries are pre-linked (no -ObjC needed) and the model bundles ship as
// SwiftPM resources.
//
// Shared Google libraries (GoogleUtilities, GoogleDataTransport, GTMSessionFetcher, nanopb,
// Promises) are NOT bundled. They resolve from their official packages with ranges that
// match Firebase iOS SDK 10.x, so Firebase and ML Kit share a single copy of each.

import PackageDescription

// GitHub release the .xcframework.zip files are attached to.
let releaseURL = "https://github.com/PbutronB/mlkit/releases/download/3.2.3"

let package = Package(
  name: "GoogleMLKit",
  platforms: [.iOS(.v13)],
  products: [
    // Everything: Face detection, Image labeling, Object detection, Text recognition.
    .library(name: "MLKit", targets: ["MLKit"]),
  ],
  dependencies: [
    // Same ranges Firebase 10.29.0 uses, so SPM picks one version for both.
    .package(url: "https://github.com/google/GoogleUtilities.git", "7.12.1" ..< "8.0.0"),
    .package(url: "https://github.com/google/GoogleDataTransport.git", "9.3.0" ..< "10.0.0"),
    .package(url: "https://github.com/google/gtm-session-fetcher.git", "2.1.0" ..< "4.0.0"),
    .package(url: "https://github.com/firebase/nanopb.git", "2.30909.0" ..< "2.30911.0"),
    .package(url: "https://github.com/google/promises.git", "2.1.0" ..< "3.0.0"),
  ],
  targets: [
    // `import MLKit`, same umbrella module CocoaPods provides. Re-exports every ML Kit module.
    .target(
      name: "MLKit",
      dependencies: [
        "MLKitResources",
        "MLImage",
        "MLKitCommon",
        "MLKitVision",
        "MLKitVisionKit",
        "MLKitFaceDetection",
        "MLKitImageLabeling",
        "MLKitImageLabelingCommon",
        "MLKitObjectDetection",
        "MLKitObjectDetectionCommon",
        "MLKitTextRecognition",
        "MLKitTextRecognitionCommon",
        "GoogleToolboxForMac",
        "GoogleUtilitiesComponents",
        "Protobuf",
        .product(name: "GULEnvironment", package: "GoogleUtilities"),
        .product(name: "GULLogger", package: "GoogleUtilities"),
        .product(name: "GULUserDefaults", package: "GoogleUtilities"),
        .product(name: "GULNSData", package: "GoogleUtilities"),
        .product(name: "GoogleDataTransport", package: "GoogleDataTransport"),
        .product(name: "GTMSessionFetcherCore", package: "gtm-session-fetcher"),
        .product(name: "nanopb", package: "nanopb"),
        .product(name: "FBLPromises", package: "promises"),
      ],
      path: "Sources/MLKit",
      linkerSettings: [
        .linkedLibrary("c++"),
        .linkedLibrary("z"),
        .linkedFramework("Accelerate"),
        .linkedFramework("AVFoundation"),
        .linkedFramework("CoreImage"),
        .linkedFramework("CoreLocation"),
        .linkedFramework("CoreMedia"),
        .linkedFramework("CoreTelephony"),
        .linkedFramework("CoreVideo"),
        .linkedFramework("Metal"),
        .linkedFramework("SystemConfiguration"),
      ]),

    // ML Kit's model bundles, plus a small lookup shim so ML Kit finds them inside the
    // SwiftPM resource bundle (CocoaPods copies them to the app root instead).
    .target(
      name: "MLKitResources",
      path: "Sources/MLKitResources",
      resources: [.copy("ModelBundles")]),

    // MARK: Binaries (built by scripts/build-xcframeworks.sh, attached to the GitHub release)
    .binaryTarget(
      name: "MLImage",
      url: "\(releaseURL)/MLImage.xcframework.zip",
      checksum: "d5a4c89f4ed306b013c03a2b7adc596f2bc0990b1b959996495fa7792f7a4ecd"),
    .binaryTarget(
      name: "MLKitCommon",
      url: "\(releaseURL)/MLKitCommon.xcframework.zip",
      checksum: "1761251a56daeb00dac03a618833ae962686970d482b3de5fbcdd142627b1cc8"),
    .binaryTarget(
      name: "MLKitVision",
      url: "\(releaseURL)/MLKitVision.xcframework.zip",
      checksum: "6d2cbc4499dadb67773d4033ca361ee0bcd045f552998158c35ab9aec6645593"),
    .binaryTarget(
      name: "MLKitVisionKit",
      url: "\(releaseURL)/MLKitVisionKit.xcframework.zip",
      checksum: "7c35eb9824ed59b95533fa77818c21e6b52115c422cb90380882fdccc446c29d"),
    .binaryTarget(
      name: "MLKitFaceDetection",
      url: "\(releaseURL)/MLKitFaceDetection.xcframework.zip",
      checksum: "34598da92f34780e128e327a0e946c146fbeaec0fc611d912d3f40995dd2d605"),
    .binaryTarget(
      name: "MLKitImageLabeling",
      url: "\(releaseURL)/MLKitImageLabeling.xcframework.zip",
      checksum: "5bdd12c8d2e653b990c496eea8b971df6c8c9acfed4a96e29e3e90447da88ed5"),
    .binaryTarget(
      name: "MLKitImageLabelingCommon",
      url: "\(releaseURL)/MLKitImageLabelingCommon.xcframework.zip",
      checksum: "568fdc035f88f5ff003b297b485a29d6330e346da2cc364eaa45b3dd984d5d4b"),
    .binaryTarget(
      name: "MLKitObjectDetection",
      url: "\(releaseURL)/MLKitObjectDetection.xcframework.zip",
      checksum: "f14e2a2aa56733313d1659912c9f3113e8e9cb5033aea33b31a02b6992600e87"),
    .binaryTarget(
      name: "MLKitObjectDetectionCommon",
      url: "\(releaseURL)/MLKitObjectDetectionCommon.xcframework.zip",
      checksum: "7ca1a38ca1f6d862c1ea1e7c6c1a2b03b356d7e6fa82eccbd306a83ec65cd795"),
    .binaryTarget(
      name: "MLKitTextRecognition",
      url: "\(releaseURL)/MLKitTextRecognition.xcframework.zip",
      checksum: "dea5b50c4d44c6d45d451982f7beadd9717a6bda59d9611866a9f523e030354b"),
    .binaryTarget(
      name: "MLKitTextRecognitionCommon",
      url: "\(releaseURL)/MLKitTextRecognitionCommon.xcframework.zip",
      checksum: "c4aac09ea36cd7ed0f97cd9434663f2d87fc90686d0395d3e284d0d0930d7ecf"),

    // Not part of Firebase 10.x, required by ML Kit.
    .binaryTarget(
      name: "GoogleToolboxForMac",
      url: "\(releaseURL)/GoogleToolboxForMac.xcframework.zip",
      checksum: "7f207a488d407e9a005ecdf8eff751daf6cc661f466b75c53fa4db90ef960cb3"),
    .binaryTarget(
      name: "GoogleUtilitiesComponents",
      url: "\(releaseURL)/GoogleUtilitiesComponents.xcframework.zip",
      checksum: "3f8bd491c3355431a207f23a28b90ef1a3108e156d3d0a0751e52d85bebde0fd"),
    .binaryTarget(
      name: "Protobuf",
      url: "\(releaseURL)/Protobuf.xcframework.zip",
      checksum: "8c4aa9f2de3a72f0660a90b1a2f33fcc624bc816ad960b4290b2c60d6a584bd4"),
  ]
)
