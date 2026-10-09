# GoogleMLKit 3.2.0 for Swift Package Manager

Swift Package for the Google ML Kit 3.2.0 binaries that CocoaPods ships as:

```ruby
pod 'GoogleMLKit/FaceDetection',   '~> 3.2.0'
pod 'GoogleMLKit/ImageLabeling',   '~> 3.2.0'
pod 'GoogleMLKit/ObjectDetection', '~> 3.2.0'
pod 'GoogleMLKit/TextRecognition', '~> 3.2.0'
```

Built to live next to the official **Firebase iOS SDK 10.x** Swift package.

## Installation

1. **File > Add Package Dependencies…** → `https://github.com/PbutronB/mlkit`, version `3.2.3` (Up to Next Minor).
2. Add the **`MLKit`** product to your app target.

That's it. No linker flags, no bundles to copy, no build phases. Use it like the pod:

```swift
import MLKit   // or the individual modules: MLKitFaceDetection, MLKitVision, MLKitTextRecognition, …
```

## What's included and what isn't

| Library | Source |
|---|---|
| MLImage, MLKitCommon, MLKitVision, MLKitVisionKit, MLKitFaceDetection, MLKitImageLabeling(+Common), MLKitObjectDetection(+Common), MLKitTextRecognition(+Common) | Binaries in this repo's release |
| GoogleToolboxForMac 2.3.2, GoogleUtilitiesComponents 1.1.0, Protobuf 3.26.1 (Obj-C) | Binaries in this repo's release (Firebase 10.x doesn't ship them) |
| GoogleUtilities, GoogleDataTransport, GTMSessionFetcher, nanopb, Promises | **Not bundled.** Resolved from the official packages using Firebase 10.29.0's version ranges, so the app ends up with one copy of each |
| Model files (face, Latin text, object, labeling) | SwiftPM resources of the `MLKitResources` target |

## How the CocoaPods-only parts were removed

- **`-ObjC`**: every static library is pre-linked into a single object (`ld -r -all_load`), so the app linker keeps all of it, Objective-C categories included.
- **Model bundles**: ML Kit looks for `GoogleMVFaceDetectorResources.bundle` etc. at the root of the app. They ship inside `GoogleMLKit_MLKitResources.bundle`, and [`MLKitResources.m`](Sources/MLKitResources/MLKitResources.m) redirects only those five lookups there. If an app also copies the bundles to its root, those are used instead.
- **`import MLKit`**: the `MLKit` target provides the same umbrella module the pod does.
- **Apple Silicon simulator**: the arm64 device slice is re-tagged as arm64-simulator, so no Rosetta and no `EXCLUDED_ARCHS`.
- **Privacy manifests**: Protobuf and GoogleToolboxForMac are on Apple's list of commonly used SDKs, so their frameworks carry the upstream `PrivacyInfo.xcprivacy` files from [`PrivacyManifests/`](PrivacyManifests).
- **dSYM warnings**: pre-linking drops the debug map (`ld -r -S`), which otherwise points at a deleted temp file and makes the app's dSYM step print `unable to open object file`. Code and symbols are unchanged.
- **Embedded bitcode**: stripped from every object before pre-linking. `ld -r` would otherwise merge each file's bitcode into one section (208 modules in MLKitCommon), which obfuscators that re-read bitcode reject (iXGuard: `The amount of found bitcode files does not match the amount of found command groups`). Bitcode has been unused since Xcode 14; machine code and symbols are identical to 3.2.2.

## Verified

A test app with the `MLKit` product plus `FirebaseAnalytics`, `FirebaseMessaging`, `FirebaseCrashlytics` and `FirebasePerformance` 10.29.0, with no build-setting changes:

- Builds and links for device (arm64), arm64 simulator and x86_64 simulator.
- On the iOS 16 arm64 simulator, all four detectors return results: face detection (1 face), text recognition (`"HELLO MLKIT 12345"`), object detection (1 object, classified) and image labeling (10 labels).

## Limitations

- **Firebase 11+ isn't supported.** It moves GoogleUtilities to 8.x and GoogleDataTransport to 10.x, which ML Kit 3.2.0 was not built against.
- **GTMSessionFetcher resolves to 3.x** (Firebase 10.29.0 requires ≥ 2.1). Every API ML Kit uses from it exists in 3.x; it's only used for optional model downloads and usage logging, not for on-device detection.
- **Download size.** The release zips total ~125 MB, mostly MLKitTextRecognitionCommon, MLKitVisionKit and MLKitFaceDetection.

## Publishing a release

The `.xcframework.zip` files are too big for git and are attached to a GitHub release instead.

1. Build the artifacts from a CocoaPods install of the 4 pods above:
   ```sh
   scripts/build-xcframeworks.sh /path/to/project/Pods
   ```
   This writes `release-assets/*.xcframework.zip` and `release-assets/checksums.txt`, and refreshes `Sources/MLKitResources/ModelBundles`. It needs `llvm-bitcode-strip` (Xcode 26's `bitcode_strip` is broken): set `BITCODE_STRIP`, or have it on `PATH` (`brew install llvm`), or the iXGuard toolchain installed.
2. Update the checksums and the version in `releaseURL` in `Package.swift`.
3. Commit, tag, push, and attach the zips:
   ```sh
   git tag 3.2.3 && git push origin main --tags
   gh release create 3.2.3 release-assets/*.zip --title "ML Kit 3.2.0 (package 3.2.3)"
   ```

## License

The wrapper (Package.swift, scripts, MLKitResources.m) is MIT. The ML Kit binaries and models are distributed by Google under the [ML Kit Terms of Service](https://developers.google.com/ml-kit/terms). GoogleToolboxForMac, GoogleUtilitiesComponents and Protobuf are distributed under their own licenses (Apache 2.0 / BSD-3-Clause), included in `LICENSES/`.
