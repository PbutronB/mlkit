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
let releaseURL = "https://github.com/PbutronB/mlkit/releases/download/3.2.1"

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
      checksum: "42c0624cabc521da3563b8810b311f53ff038da40f035a6d11663ef97d4b696a"),
    .binaryTarget(
      name: "MLKitCommon",
      url: "\(releaseURL)/MLKitCommon.xcframework.zip",
      checksum: "8b0acdf805176c025e390f9eb316487194a9188407a7d97fcc9aafa8fc3397ef"),
    .binaryTarget(
      name: "MLKitVision",
      url: "\(releaseURL)/MLKitVision.xcframework.zip",
      checksum: "38dcf9866fa2fc01d76123d65d8c30e3bd6725f36eb19b58822b9b6ea329772a"),
    .binaryTarget(
      name: "MLKitVisionKit",
      url: "\(releaseURL)/MLKitVisionKit.xcframework.zip",
      checksum: "679e341c11f29f0b4eabd0ecec058640f691f2a7a2e6517941c089571f2fe8cd"),
    .binaryTarget(
      name: "MLKitFaceDetection",
      url: "\(releaseURL)/MLKitFaceDetection.xcframework.zip",
      checksum: "77a78dae1780d340e1003d7e3b038555f34c7c5baad7a7935c4f2c4bec460415"),
    .binaryTarget(
      name: "MLKitImageLabeling",
      url: "\(releaseURL)/MLKitImageLabeling.xcframework.zip",
      checksum: "5db63f7a09c3e2ec679a7dfba80053969bbe3595821cd7759963e4df0f75df38"),
    .binaryTarget(
      name: "MLKitImageLabelingCommon",
      url: "\(releaseURL)/MLKitImageLabelingCommon.xcframework.zip",
      checksum: "ba99df34cffc69248ee7d0d329b2ed5b7ca599de43971c0f550fdc0929e1c5fc"),
    .binaryTarget(
      name: "MLKitObjectDetection",
      url: "\(releaseURL)/MLKitObjectDetection.xcframework.zip",
      checksum: "fa2d7224ae211684bcfc56de4f892ef3b3366b779465c982a0cd57186f750bf6"),
    .binaryTarget(
      name: "MLKitObjectDetectionCommon",
      url: "\(releaseURL)/MLKitObjectDetectionCommon.xcframework.zip",
      checksum: "ab435aa130e4e9c20f20a0910177282cbe197bd1c2dddc195f74a40da2fd86de"),
    .binaryTarget(
      name: "MLKitTextRecognition",
      url: "\(releaseURL)/MLKitTextRecognition.xcframework.zip",
      checksum: "f596858428b585a09f4dd490c918307bdb98c7e715be5710fb403e3e7e5405a1"),
    .binaryTarget(
      name: "MLKitTextRecognitionCommon",
      url: "\(releaseURL)/MLKitTextRecognitionCommon.xcframework.zip",
      checksum: "1073f3bbe50e79caf582f39f0ff2e8410e5a488519365c2a8161349627908eef"),

    // Not part of Firebase 10.x, required by ML Kit.
    .binaryTarget(
      name: "GoogleToolboxForMac",
      url: "\(releaseURL)/GoogleToolboxForMac.xcframework.zip",
      checksum: "d56e7b02b869fe0d89d801572fbf3dd62b28d3bcdb76176a58591cfeec4fef72"),
    .binaryTarget(
      name: "GoogleUtilitiesComponents",
      url: "\(releaseURL)/GoogleUtilitiesComponents.xcframework.zip",
      checksum: "ec74472dd89abd3715082a4414e53dcb0c6539d9b2e78b6645cac06e5ddb3cf5"),
    .binaryTarget(
      name: "Protobuf",
      url: "\(releaseURL)/Protobuf.xcframework.zip",
      checksum: "1c5c79e24f534b780459793ac603325e2f5632dd7a1547b94c8d4dd859c8affd"),
  ]
)
