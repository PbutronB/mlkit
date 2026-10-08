#!/bin/bash
# Builds the binary artifacts for this package from an existing CocoaPods install of
# GoogleMLKit 3.2.0 (FaceDetection, ImageLabeling, ObjectDetection, TextRecognition).
#
# Usage: scripts/build-xcframeworks.sh /path/to/project/Pods
#
# Output (relative to the package root):
#   release-assets/*.xcframework.zip  -> upload to the GitHub release (NOT committed, see .gitignore)
#   release-assets/checksums.txt      -> values used in Package.swift
#   Sources/MLKitResources/ModelBundles -> ML Kit model bundles, shipped as SwiftPM resources
#
# Only ML Kit's own binaries plus three libraries Firebase 10.x does NOT ship are packaged here:
# GoogleToolboxForMac, GoogleUtilitiesComponents and Protobuf (Objective-C runtime).
# GoogleUtilities, GoogleDataTransport, GTMSessionFetcher, nanopb and Promises are resolved
# from their official Swift packages so they are shared with Firebase.
#
# Every static library is pre-linked into a single object (ld -r -all_load). The app linker then
# keeps all of it, including Objective-C categories, so consumers don't need -ObjC.
# The arm64 device slice is re-tagged as arm64-simulator so Apple Silicon simulators work.
set -euo pipefail

PODS="${1:?Usage: $0 /path/to/Pods}"
PODS="$(cd "$PODS" && pwd)"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
OUT="$ROOT/release-assets"
XCF="$WORK/xcframeworks"
RES="$ROOT/Sources/MLKitResources/ModelBundles"
MIN_IOS=13.0
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

rm -rf "$OUT" "$RES"
mkdir -p "$OUT" "$XCF" "$RES"

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
  <key>MinimumOSVersion</key><string>$MIN_IOS</string>
</dict>
</plist>
EOF
}

# Pre-links one architecture of a static library (archive or relocatable object) into a single
# relocatable object. $1 input, $2 arch, $3 platform (ios | ios-simulator), $4 output.
prelink() {
  local in="$1" arch="$2" platform="$3" out="$4" thin="$WORK/thin.$$"
  if [ "$(lipo -archs "$in")" = "$arch" ]; then cp "$in" "$thin"; else lipo "$in" -thin "$arch" -output "$thin"; fi
  if [ "$(file -b "$thin" | cut -c1-10)" = "current ar" ] || file -b "$thin" | grep -q "ar archive"; then
    # -keep_private_externs keeps hidden symbols visible across the pre-linked object boundary.
    xcrun ld -r -arch "$arch" -platform_version "$platform" "$MIN_IOS" "$MIN_IOS" \
      -all_load -keep_private_externs "$thin" -o "$out" 2> >(grep -v "^ld: warning" >&2)
  else
    cp "$thin" "$out"
  fi
  rm -f "$thin"
}

# Re-tags an iOS-device arm64 object as iOS-simulator (platform 7). The code is identical; only
# the platform load command differs. Falls back to rebuilding the load command with ld -r when
# vtool can't grow the header in place.
retag_simulator() {
  local in="$1" out="$2"
  if ! xcrun vtool -set-build-version 7 "$MIN_IOS" "$MIN_IOS" -replace -output "$out" "$in" 2>/dev/null; then
    echo "vtool failed for $in" >&2; return 1
  fi
}

# Writes a framework directory for one slice with the given binary.
make_slice() {
  local name="$1" src="$2" dir="$3" bin="$4"
  mkdir -p "$dir"
  for sub in Headers Modules PrivateHeaders; do
    [ -d "$src/$sub" ] && cp -R "$src/$sub" "$dir/"
  done
  mv "$bin" "$dir/$name"
  framework_info_plist "$dir" "$name"
}

# Builds a static XCFramework for $name from a framework that contains arm64 (device) and,
# optionally, x86_64 (simulator) slices.
make_xcframework() {
  local name="$1" dev_src="$2" sim_src="$3"
  local tmp="$WORK/slices/$name"
  rm -rf "$tmp"; mkdir -p "$tmp"

  prelink "$dev_src/$name" arm64 ios "$tmp/dev.o"
  retag_simulator "$tmp/dev.o" "$tmp/sim_arm64.o"
  if lipo -archs "$sim_src/$name" | grep -q x86_64; then
    prelink "$sim_src/$name" x86_64 ios-simulator "$tmp/sim_x86_64.o"
    lipo -create "$tmp/sim_arm64.o" "$tmp/sim_x86_64.o" -output "$tmp/sim.o"
  else
    mv "$tmp/sim_arm64.o" "$tmp/sim.o"
  fi
  # Static libraries are archives; wrap each pre-linked object so Xcode treats it as one.
  for s in dev sim; do
    for a in $(lipo -archs "$tmp/$s.o"); do
      lipo "$tmp/$s.o" -thin "$a" -output "$tmp/$s.$a.o" 2>/dev/null || cp "$tmp/$s.o" "$tmp/$s.$a.o"
      xcrun libtool -static -o "$tmp/$s.$a.a" "$tmp/$s.$a.o" 2> >(grep -v "has no symbols" >&2)
    done
    lipo -create "$tmp/$s".*.a -output "$tmp/$s.a"
  done

  make_slice "$name" "$dev_src" "$tmp/ios-arm64/$name.framework" "$tmp/dev.a"
  make_slice "$name" "$dev_src" "$tmp/ios-sim/$name.framework" "$tmp/sim.a"
  xcodebuild -create-xcframework \
    -framework "$tmp/ios-arm64/$name.framework" \
    -framework "$tmp/ios-sim/$name.framework" \
    -output "$XCF/$name.xcframework" >/dev/null
}

# 1. ML Kit binaries (fat arm64 + x86_64 static frameworks from the pods).
for name in "${MLKIT_FRAMEWORKS[@]}"; do
  echo "==> $name"
  src="$PODS/$name/Frameworks/$name.framework"
  make_xcframework "$name" "$src" "$src"
done

# 2. Source pods that Firebase doesn't provide, built from the Pods project (keeps the per-file
#    -fno-objc-arc flags Protobuf and GTM need) as static frameworks, then packaged like ML Kit.
BUILD="$WORK/build"
for sdk in iphoneos iphonesimulator; do
  archs="arm64"; [ "$sdk" = iphonesimulator ] && archs="x86_64"
  targets=()
  for t in "${SOURCE_PODS[@]}"; do targets+=(-target "$t"); done
  if [ "$sdk" = iphoneos ]; then
    for t in "${RESOURCE_TARGETS[@]}"; do targets+=(-target "$t"); done
  fi
  echo "==> xcodebuild $sdk"
  xcodebuild -project "$PODS/Pods.xcodeproj" "${targets[@]}" \
    -sdk "$sdk" -configuration Release \
    ARCHS="$archs" ONLY_ACTIVE_ARCH=NO \
    MACH_O_TYPE=staticlib IPHONEOS_DEPLOYMENT_TARGET="$MIN_IOS" \
    CLANG_ENABLE_MODULE_DEBUGGING=NO DEBUG_INFORMATION_FORMAT=dwarf \
    GCC_WARN_INHIBIT_ALL_WARNINGS=YES CODE_SIGNING_ALLOWED=NO \
    SYMROOT="$BUILD" OBJROOT="$WORK/obj" -quiet 2>&1 | grep -E "error:" || true
done

for name in "${SOURCE_PODS[@]}"; do
  echo "==> $name"
  make_xcframework "$name" \
    "$BUILD/Release-iphoneos/$name/$name.framework" \
    "$BUILD/Release-iphonesimulator/$name/$name.framework"
done

# 3. Model bundles -> SwiftPM resources of the MLKitResources target.
for t in "${RESOURCE_TARGETS[@]}"; do
  pod="${t%%-*}"; bundle="${t#*-}.bundle"
  cp -R "$BUILD/Release-iphoneos/$pod/$bundle" "$RES/"
done
find "$RES" -name "_CodeSignature" -prune -exec rm -rf {} +

# 4. Zip + checksums for the release.
: > "$OUT/checksums.txt"
for x in "$XCF"/*.xcframework; do
  name="$(basename "$x" .xcframework)"
  (cd "$XCF" && ditto -c -k --sequesterRsrc --keepParent "$name.xcframework" "$OUT/$name.xcframework.zip")
  sum="$(swift package compute-checksum "$OUT/$name.xcframework.zip")"
  echo "$name $sum" >> "$OUT/checksums.txt"
  printf "%-28s %6s  %s\n" "$name" "$(du -h "$OUT/$name.xcframework.zip" | cut -f1)" "$sum"
done
