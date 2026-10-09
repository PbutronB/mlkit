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
let releaseURL = "https://github.com/PbutronB/mlkit/releases/download/3.2.2"

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
      checksum: "4e680ef25ca4930cb392f31e2187ba56d91723d64a211aba0f38ecf7929066e6"),
    .binaryTarget(
      name: "MLKitCommon",
      url: "\(releaseURL)/MLKitCommon.xcframework.zip",
      checksum: "0659201f5b7e0b8b42b74e90c02462f6b1cfdb1fc7c2f6506b63d3b89dee9fbb"),
    .binaryTarget(
      name: "MLKitVision",
      url: "\(releaseURL)/MLKitVision.xcframework.zip",
      checksum: "5a6601e7a3ddc36c989598599c154285957cb489147509dfc1cb32006118ef9f"),
    .binaryTarget(
      name: "MLKitVisionKit",
      url: "\(releaseURL)/MLKitVisionKit.xcframework.zip",
      checksum: "c91bd2a708ac47072afe30bd0cff0040b8740cd1445f0b95e1dab26cf38fb5a2"),
    .binaryTarget(
      name: "MLKitFaceDetection",
      url: "\(releaseURL)/MLKitFaceDetection.xcframework.zip",
      checksum: "6355313cead6e675234f14b9adf1f6de196f2cbcc57743160790078df6dcb1bb"),
    .binaryTarget(
      name: "MLKitImageLabeling",
      url: "\(releaseURL)/MLKitImageLabeling.xcframework.zip",
      checksum: "7ffc08d06729d4916e622e5797f06aa2997ece49408cb6aa3a0edee3e0771843"),
    .binaryTarget(
      name: "MLKitImageLabelingCommon",
      url: "\(releaseURL)/MLKitImageLabelingCommon.xcframework.zip",
      checksum: "22617d016eac596f7dadced9ae505ecf6be0100794be7fa0ecea3ae43208d8ee"),
    .binaryTarget(
      name: "MLKitObjectDetection",
      url: "\(releaseURL)/MLKitObjectDetection.xcframework.zip",
      checksum: "cefab6e5e09028ba1e41aeb71689e20481b4e1b35a667884a104a7d3b176cdb3"),
    .binaryTarget(
      name: "MLKitObjectDetectionCommon",
      url: "\(releaseURL)/MLKitObjectDetectionCommon.xcframework.zip",
      checksum: "ae124daad7e3424ca730d8ea451f260f739f1b8221d35636606b65e181c2bbf6"),
    .binaryTarget(
      name: "MLKitTextRecognition",
      url: "\(releaseURL)/MLKitTextRecognition.xcframework.zip",
      checksum: "220ec1eae4184fab74e8d7dc6ef6579c89260287412ac3bd12ea63e44599f2e7"),
    .binaryTarget(
      name: "MLKitTextRecognitionCommon",
      url: "\(releaseURL)/MLKitTextRecognitionCommon.xcframework.zip",
      checksum: "ac1877b0a636b29733d2cf53d0d2716698283fc14cdb926eac35fda707f47045"),

    // Not part of Firebase 10.x, required by ML Kit.
    .binaryTarget(
      name: "GoogleToolboxForMac",
      url: "\(releaseURL)/GoogleToolboxForMac.xcframework.zip",
      checksum: "48ceba151ff373bc490413684409fa9d28b6171c30c1d38f7fb462f4d31fe80f"),
    .binaryTarget(
      name: "GoogleUtilitiesComponents",
      url: "\(releaseURL)/GoogleUtilitiesComponents.xcframework.zip",
      checksum: "61b2646910945c4f1ec3c629d665f41c820abff32847d974bff2133871ebb5be"),
    .binaryTarget(
      name: "Protobuf",
      url: "\(releaseURL)/Protobuf.xcframework.zip",
      checksum: "f4f122a81ed2ea9c22dd931c5bb81319ea89e50ee6891c6149dc149ee4006adc"),
  ]
)
