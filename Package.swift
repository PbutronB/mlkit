// swift-tools-version:5.7
// Swift Package wrapper for Google ML Kit 3.2.0 (the CocoaPods `GoogleMLKit/*` 3.2.0 subspecs):
// FaceDetection, ImageLabeling, ObjectDetection and TextRecognition (Latin).
//
// Shared Google libraries (GoogleUtilities, GoogleDataTransport, GTMSessionFetcher, nanopb,
// Promises) are NOT bundled. They resolve from their official packages with ranges that
// match Firebase iOS SDK 10.x, so Firebase and ML Kit share a single copy of each.

import PackageDescription

// GitHub release the .xcframework.zip files are attached to.
let releaseURL = "https://github.com/PbutronB/mlkit/releases/download/3.2.0"

let package = Package(
  name: "GoogleMLKit",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "MLKitFaceDetection", targets: ["FaceDetection"]),
    .library(name: "MLKitImageLabeling", targets: ["ImageLabeling"]),
    .library(name: "MLKitObjectDetection", targets: ["ObjectDetection"]),
    .library(name: "MLKitTextRecognition", targets: ["TextRecognition"]),
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
    // MARK: Feature targets (thin wrappers so each product pulls only what it needs)
    .target(
      name: "FaceDetection",
      dependencies: ["MLKitFaceDetection", "VisionCore"],
      path: "Sources/FaceDetection"),
    .target(
      name: "ImageLabeling",
      dependencies: ["MLKitImageLabeling", "MLKitImageLabelingCommon", "MLKitVisionKit", "VisionCore"],
      path: "Sources/ImageLabeling"),
    .target(
      name: "ObjectDetection",
      dependencies: ["MLKitObjectDetection", "MLKitObjectDetectionCommon", "MLKitVisionKit", "VisionCore"],
      path: "Sources/ObjectDetection"),
    .target(
      name: "TextRecognition",
      dependencies: ["MLKitTextRecognition", "MLKitTextRecognitionCommon", "VisionCore"],
      path: "Sources/TextRecognition"),

    // MARK: Shared core: MLKitCommon + MLKitVision + their dependencies
    .target(
      name: "VisionCore",
      dependencies: [
        "MLImage",
        "MLKitCommon",
        "MLKitVision",
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
      path: "Sources/VisionCore",
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

    // MARK: Binaries (built by scripts/build-xcframeworks.sh, attached to the GitHub release)
    .binaryTarget(
      name: "MLImage",
      url: "\(releaseURL)/MLImage.xcframework.zip",
      checksum: "d42765843a4214226cfb6a0b083f942366eb28792706f1e34e7bb65bc498566d"),
    .binaryTarget(
      name: "MLKitCommon",
      url: "\(releaseURL)/MLKitCommon.xcframework.zip",
      checksum: "75211041016d7f0c500585122a6f55f44c473f180474770bf5344ba4de473cd6"),
    .binaryTarget(
      name: "MLKitVision",
      url: "\(releaseURL)/MLKitVision.xcframework.zip",
      checksum: "7e997ee6f4a4aed78d2b559f0e21c67e4479c70ac6252f58bd9042d5aa8e6bd0"),
    .binaryTarget(
      name: "MLKitVisionKit",
      url: "\(releaseURL)/MLKitVisionKit.xcframework.zip",
      checksum: "4aef123e237480a9c2cc169d5e40aaa43c7f3c7bedc01278bffa15bb37c854a6"),
    .binaryTarget(
      name: "MLKitFaceDetection",
      url: "\(releaseURL)/MLKitFaceDetection.xcframework.zip",
      checksum: "fde5e213d6c990b7baabe2e49bfe2404846490e0607d9ae550aa4d27d9ff53c4"),
    .binaryTarget(
      name: "MLKitImageLabeling",
      url: "\(releaseURL)/MLKitImageLabeling.xcframework.zip",
      checksum: "db4c644d7dff2a98e56efdb7638ba49c4502cffd11c8cad6616d85ce1af0c6e8"),
    .binaryTarget(
      name: "MLKitImageLabelingCommon",
      url: "\(releaseURL)/MLKitImageLabelingCommon.xcframework.zip",
      checksum: "08f017578447bbfbfc92dde419cc240bcf974220e4c5e05500066f1fa20059c6"),
    .binaryTarget(
      name: "MLKitObjectDetection",
      url: "\(releaseURL)/MLKitObjectDetection.xcframework.zip",
      checksum: "39268b7d34dcaca2f96bac3c08d0cb303f2ec023f18e1d4054a580fee4f5bceb"),
    .binaryTarget(
      name: "MLKitObjectDetectionCommon",
      url: "\(releaseURL)/MLKitObjectDetectionCommon.xcframework.zip",
      checksum: "35b7de3c5cfc31da276fce909ea61c5521c9afed7755dcb6f10453ea618418a0"),
    .binaryTarget(
      name: "MLKitTextRecognition",
      url: "\(releaseURL)/MLKitTextRecognition.xcframework.zip",
      checksum: "864d613cb3f4cda0bfce6837aec18f76d6f3f10ec321e977994e3bbc6d0e5104"),
    .binaryTarget(
      name: "MLKitTextRecognitionCommon",
      url: "\(releaseURL)/MLKitTextRecognitionCommon.xcframework.zip",
      checksum: "d009105f022f6d08d3d0ea59cf5d41ca887fb33869b5c374603af811dd7bfaed"),

    // Not part of Firebase 10.x, required by ML Kit.
    .binaryTarget(
      name: "GoogleToolboxForMac",
      url: "\(releaseURL)/GoogleToolboxForMac.xcframework.zip",
      checksum: "67f1a469fc0bd31d4b2dce092b1f65c6f451d5a631527fe9f87fdf3733e98eeb"),
    .binaryTarget(
      name: "GoogleUtilitiesComponents",
      url: "\(releaseURL)/GoogleUtilitiesComponents.xcframework.zip",
      checksum: "1f9576d39fc75f40993b00b23dd901c04b11d0840b2c8edfcaa6de7ae03352b1"),
    .binaryTarget(
      name: "Protobuf",
      url: "\(releaseURL)/Protobuf.xcframework.zip",
      checksum: "44bf82c0ac871c56ba6cd33351b5b2124f4088da7a7d46ef7c6aecf4ca738202"),
  ]
)
