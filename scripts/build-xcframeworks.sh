#!/bin/bash
# Builds the binary artifacts for this package from an existing CocoaPods install of
# GoogleMLKit 3.2.0 (FaceDetection, ImageLabeling, ObjectDetection, TextRecognition).
#
# Usage: scripts/build-xcframeworks.sh /path/to/project/Pods
#
# Output (relative to the package root):
#   release-assets/*.xcframework.zip  -> upload to the GitHub release (NOT committed, see .gitignore)
#   release-assets/checksums.txt      -> values used in Package.swift
#   Resources/*.bundle                -> ML Kit model bundles, committed, added to the app target manually
#
# Only ML Kit's own binaries plus three libraries Firebase 10.x does NOT ship are packaged here:
# GoogleToolboxForMac, GoogleUtilitiesComponents and Protobuf (Objective-C runtime).
# GoogleUtilities, GoogleDataTransport, GTMSessionFetcher, nanopb and Promises are resolved
# from their official Swift packages so they are shared with Firebase.
set -euo pipefail

PODS="${1:?Usage: $0 /path/to/Pods}"
PODS="$(cd "$PODS" && pwd)"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
OUT="$ROOT/release-assets"
XCF="$WORK/xcframeworks"
trap 'rm -rf "$WORK"' EXIT

MLKIT_FRAMEWORKS=(
  MLImage
  MLKitCommon
  MLKitVision
  MLKitVisionKit
  MLKitFaceDetection
  MLKitImageLabeling
  MLKitImageLabelingCommon
  MLKitObjectDetection
  MLKitObjectDetectionCommon
  MLKitTextRecognition
  MLKitTextRecognitionCommon
)
SOURCE_PODS=(GoogleToolboxForMac GoogleUtilitiesComponents Protobuf)
RESOURCE_TARGETS=(
  MLKitFaceDetection-GoogleMVFaceDetectorResources
  MLKitImageLabeling-MLKitImageLabelingResources
  MLKitObjectDetection-MLKitObjectDetectionResources
  MLKitObjectDetectionCommon-MLKitObjectDetectionCommonResources
  MLKitTextRecognition-LatinOCRResources
)

rm -rf "$OUT" "$ROOT/Resources"
mkdir -p "$OUT" "$XCF" "$ROOT/Resources"

framework_info_plist() {
  cat > "$1/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>$2</string>
  <key>CFBundleIdentifier</key><string>com.google.mlkit.$2</string>
  <key>CFBundleName</key><string>$2</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>3.2.0</string>
  <key>CFBundleVersion</key><string>3.2.0</string>
  <key>MinimumOSVersion</key><string>13.0</string>
</dict>
</plist>
EOF
}

# 1. ML Kit: the pods ship fat static frameworks (arm64 device + x86_64 simulator).
#    Split them into an XCFramework by hand; xcodebuild -create-xcframework can't tell the
#    legacy x86_64 slice is a simulator slice.
for name in "${MLKIT_FRAMEWORKS[@]}"; do
  src="$PODS/$name/Frameworks/$name.framework"
  dst="$XCF/$name.xcframework"
  echo "==> $name"
  for slice in "ios-arm64:arm64" "ios-x86_64-simulator:x86_64"; do
    dir="$dst/${slice%%:*}/$name.framework"
    mkdir -p "$dir"
    for sub in Headers Modules; do
      [ -d "$src/$sub" ] && cp -R "$src/$sub" "$dir/"
    done
    lipo "$src/$name" -thin "${slice##*:}" -output "$dir/$name"
    framework_info_plist "$dir" "$name"
  done
  cat > "$dst/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>AvailableLibraries</key>
  <array>
    <dict>
      <key>BinaryPath</key><string>$name.framework/$name</string>
      <key>LibraryIdentifier</key><string>ios-arm64</string>
      <key>LibraryPath</key><string>$name.framework</string>
      <key>SupportedArchitectures</key><array><string>arm64</string></array>
      <key>SupportedPlatform</key><string>ios</string>
    </dict>
    <dict>
      <key>BinaryPath</key><string>$name.framework/$name</string>
      <key>LibraryIdentifier</key><string>ios-x86_64-simulator</string>
      <key>LibraryPath</key><string>$name.framework</string>
      <key>SupportedArchitectures</key><array><string>x86_64</string></array>
      <key>SupportedPlatform</key><string>ios</string>
      <key>SupportedPlatformVariant</key><string>simulator</string>
    </dict>
  </array>
  <key>CFBundlePackageType</key><string>XFWK</string>
  <key>XCFrameworkFormatVersion</key><string>1.0</string>
</dict>
</plist>
EOF
done

# 2. Source pods that Firebase doesn't provide: build them as static frameworks from the
#    Pods project (keeps the per-file -fno-objc-arc flags Protobuf/GTM need).
BUILD="$WORK/build"
for sdk in iphoneos iphonesimulator; do
  archs="arm64"; [ "$sdk" = iphonesimulator ] && archs="arm64 x86_64"
  targets=()
  for t in "${SOURCE_PODS[@]}"; do targets+=(-target "$t"); done
  if [ "$sdk" = iphoneos ]; then
    for t in "${RESOURCE_TARGETS[@]}"; do targets+=(-target "$t"); done
  fi
  echo "==> xcodebuild $sdk"
  xcodebuild -project "$PODS/Pods.xcodeproj" "${targets[@]}" \
    -sdk "$sdk" -configuration Release \
    ARCHS="$archs" ONLY_ACTIVE_ARCH=NO \
    MACH_O_TYPE=staticlib IPHONEOS_DEPLOYMENT_TARGET=13.0 \
    CLANG_ENABLE_MODULE_DEBUGGING=NO DEBUG_INFORMATION_FORMAT=dwarf \
    CODE_SIGNING_ALLOWED=NO \
    SYMROOT="$BUILD" OBJROOT="$WORK/obj" -quiet
done

for name in "${SOURCE_PODS[@]}"; do
  echo "==> $name"
  xcodebuild -create-xcframework \
    -framework "$BUILD/Release-iphoneos/$name/$name.framework" \
    -framework "$BUILD/Release-iphonesimulator/$name/$name.framework" \
    -output "$XCF/$name.xcframework" >/dev/null
  # Privacy bundles are emitted next to the framework, not inside; drop leftovers if any.
  find "$XCF/$name.xcframework" -name "_CodeSignature" -prune -exec rm -rf {} +
done

# 3. Model bundles. ML Kit looks them up by name in the main bundle, so they can't live in an
#    SPM resource bundle; they're committed and added to the app target's Copy Bundle Resources.
for t in "${RESOURCE_TARGETS[@]}"; do
  pod="${t%%-*}"; bundle="${t#*-}.bundle"
  cp -R "$BUILD/Release-iphoneos/$pod/$bundle" "$ROOT/Resources/"
done
find "$ROOT/Resources" -name "_CodeSignature" -prune -exec rm -rf {} +

# 4. Zip + checksums for the release.
: > "$OUT/checksums.txt"
for x in "$XCF"/*.xcframework; do
  name="$(basename "$x" .xcframework)"
  (cd "$XCF" && ditto -c -k --sequesterRsrc --keepParent "$name.xcframework" "$OUT/$name.xcframework.zip")
  sum="$(swift package compute-checksum "$OUT/$name.xcframework.zip")"
  echo "$name $sum" >> "$OUT/checksums.txt"
  printf "%-28s %6s  %s\n" "$name" "$(du -h "$OUT/$name.xcframework.zip" | cut -f1)" "$sum"
done
