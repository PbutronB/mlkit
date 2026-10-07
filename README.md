# GoogleMLKit 3.2.0 for Swift Package Manager

Swift Package wrapper for the Google ML Kit 3.2.0 binaries that CocoaPods ships as:

```ruby
pod 'GoogleMLKit/FaceDetection',   '~> 3.2.0'
pod 'GoogleMLKit/ImageLabeling',   '~> 3.2.0'
pod 'GoogleMLKit/ObjectDetection', '~> 3.2.0'
pod 'GoogleMLKit/TextRecognition', '~> 3.2.0'
```

Built to live next to the official **Firebase iOS SDK 10.x** Swift package.

## What's included and what isn't

| Library | Source |
|---|---|
| MLImage, MLKitCommon, MLKitVision, MLKitVisionKit, MLKitFaceDetection, MLKitImageLabeling(+Common), MLKitObjectDetection(+Common), MLKitTextRecognition(+Common) | Binaries in this repo's release |
| GoogleToolboxForMac 2.3.2, GoogleUtilitiesComponents 1.1.0, Protobuf 3.26.1 (Obj-C) | Binaries in this repo's release (Firebase 10.x doesn't ship them) |
| GoogleUtilities, GoogleDataTransport, GTMSessionFetcher, nanopb, Promises | **Not bundled.** Resolved from the official packages using Firebase 10.29.0's version ranges, so the app ends up with one copy of each |

Verified: an app target with these 4 products plus `FirebaseAnalytics`, `FirebaseMessaging`, `FirebaseCrashlytics` and `FirebasePerformance` 10.29.0 resolves and links without duplicate or undefined symbols on device (arm64) and Intel simulator (x86_64).

## Installation

1. Add the package: `https://github.com/PbutronB/mlkit`, version `3.2.0`.
2. Add the products you need to your app target: `MLKitFaceDetection`, `MLKitImageLabeling`, `MLKitObjectDetection`, `MLKitTextRecognition`.
3. In the app target's **Build Settings**, add `-ObjC` to **Other Linker Flags**. ML Kit relies on Objective-C categories inside static libraries.
4. Add the model bundles from [`Resources/`](Resources) to the app target (drag into Xcode, **Copy items if needed**, target membership checked). ML Kit loads them by name from the main bundle at runtime, which SwiftPM resource bundles can't satisfy:

   | Product | Bundle(s) |
   |---|---|
   | MLKitFaceDetection | `GoogleMVFaceDetectorResources.bundle` |
   | MLKitImageLabeling | `MLKitImageLabelingResources.bundle` |
   | MLKitObjectDetection | `MLKitObjectDetectionResources.bundle`, `MLKitObjectDetectionCommonResources.bundle` |
   | MLKitTextRecognition | `LatinOCRResources.bundle` |

   If a bundle is missing, the app builds fine but the detector fails at runtime.

5. Import the modules directly: `import MLKitFaceDetection`, `import MLKitVision`, etc. The CocoaPods umbrella `import MLKit` doesn't exist in this package.

## Limitations

- **No arm64 simulator.** Google only shipped arm64 (device) and x86_64 (simulator) slices for ML Kit 3.2.0. On Apple Silicon, run the simulator under Rosetta or exclude arm64 for simulator builds (`EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64`), the same as with the pods.
- **Firebase 11+ isn't supported.** It moves GoogleUtilities to 8.x and GoogleDataTransport to 10.x, which ML Kit 3.2.0 was not built against.
- **Large download.** MLKitTextRecognitionCommon (~193 MB zipped), MLKitVisionKit (~145 MB) and MLKitFaceDetection (~81 MB) still contain Google's embedded bitcode. It's stripped at link time, so it doesn't affect app size.

## Publishing a release

The `.xcframework.zip` files are too big for git and are attached to a GitHub release instead.

1. Build the artifacts from a CocoaPods install of the 4 pods above:
   ```sh
   scripts/build-xcframeworks.sh /path/to/project/Pods
   ```
   This writes `release-assets/*.xcframework.zip` and `release-assets/checksums.txt`, and refreshes `Resources/`.
2. If the checksums changed, update them in `Package.swift`.
3. Set `releaseURL` in `Package.swift` to `https://github.com/PbutronB/mlkit/releases/download/3.2.0`.
4. Commit, tag `3.2.0`, push, then create the release and upload every file in `release-assets/` except `checksums.txt`:
   ```sh
   git tag 3.2.0 && git push origin main --tags
   gh release create 3.2.0 release-assets/*.zip --title "ML Kit 3.2.0"
   ```

## License

The wrapper (Package.swift, scripts) is MIT. The ML Kit binaries are distributed by Google under the [ML Kit Terms of Service](https://developers.google.com/ml-kit/terms). GoogleToolboxForMac, GoogleUtilitiesComponents and Protobuf are distributed under their own licenses (Apache 2.0 / BSD-3-Clause), included in `LICENSES/`.
