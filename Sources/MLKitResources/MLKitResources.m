// ML Kit 3.2 expects its model bundles (e.g. GoogleMVFaceDetectorResources.bundle) at the root of
// the app, which is where CocoaPods copies them. SwiftPM puts them inside this target's resource
// bundle instead, so this file points ML Kit there. Nothing changes if the app already contains
// the bundles at its root.
//
// How ML Kit looks them up (from the 3.2.0 binaries):
// - Face, object detection, image labeling: -[NSBundle pathForResource:<name> ofType:@"bundle"]
//   on +mainBundle / +bundleForClass:. Handled by the NSBundle hook below, limited to those names.
// - Text recognition: <bundleForClass:>.bundleURL + -[MLKCommonTextRecognizerOptions bundleName].
//   Handled by making bundleName point into the resource bundle.

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSBundle *MLKResourcesBundle(void) {
  static NSBundle *bundle;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    // SwiftPM names the bundle <package>_<target>.bundle and copies it to the app's resources.
    NSString *name = @"GoogleMLKit_MLKitResources.bundle";
    NSMutableArray<NSURL *> *candidates = [NSMutableArray array];
    if (NSBundle.mainBundle.resourceURL) [candidates addObject:NSBundle.mainBundle.resourceURL];
    [candidates addObject:NSBundle.mainBundle.bundleURL];
    // Covers the bundle being embedded next to a framework that links this package.
    for (NSBundle *framework in NSBundle.allFrameworks) {
      if (framework.resourceURL) [candidates addObject:framework.resourceURL];
    }
    for (NSURL *base in candidates) {
      NSBundle *b = [NSBundle bundleWithURL:[base URLByAppendingPathComponent:name]];
      if (b) {
        bundle = b;
        break;
      }
    }
  });
  return bundle;
}

static BOOL MLKIsModelBundleName(NSString *name) {
  static NSSet<NSString *> *names;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    names = [NSSet setWithArray:@[
      @"GoogleMVFaceDetectorResources",
      @"LatinOCRResources",
      @"MLKitImageLabelingResources",
      @"MLKitObjectDetectionResources",
      @"MLKitObjectDetectionCommonResources",
    ]];
  });
  return name != nil && [names containsObject:name];
}

#pragma mark - NSBundle pathForResource:ofType:

static NSString *(*MLKOriginalPathForResource)(id, SEL, NSString *, NSString *);

static NSString *MLKPathForResource(NSBundle *self, SEL _cmd, NSString *name, NSString *ext) {
  NSString *path = MLKOriginalPathForResource(self, _cmd, name, ext);
  if (path == nil && [ext isEqualToString:@"bundle"] && MLKIsModelBundleName(name)) {
    NSBundle *resources = MLKResourcesBundle();
    if (resources != nil && resources != self) {
      // .copy("ModelBundles") keeps the folder, so the model bundles live one level down.
      path = [resources pathForResource:name ofType:ext inDirectory:@"ModelBundles"];
    }
  }
  return path;
}

#pragma mark - MLKCommonTextRecognizerOptions bundleName

static NSString *(*MLKOriginalBundleName)(id, SEL);

static NSString *MLKBundleName(id self, SEL _cmd) {
  NSString *bundleName = MLKOriginalBundleName(self, _cmd);  // e.g. @"LatinOCRResources.bundle"
  NSString *base = bundleName.stringByDeletingPathExtension;
  if (!MLKIsModelBundleName(base)) return bundleName;

  // ML Kit appends this to the main bundle's URL. Keep it untouched if the app has the bundle at
  // its root; otherwise return the path relative to the main bundle inside the resource bundle.
  NSURL *mainURL = NSBundle.mainBundle.bundleURL;
  if ([NSFileManager.defaultManager fileExistsAtPath:[mainURL URLByAppendingPathComponent:bundleName].path]) {
    return bundleName;
  }
  NSString *resourcePath = [MLKResourcesBundle() pathForResource:base ofType:@"bundle" inDirectory:@"ModelBundles"];
  NSString *mainPath = mainURL.URLByStandardizingPath.path;
  if (resourcePath != nil && [resourcePath hasPrefix:[mainPath stringByAppendingString:@"/"]]) {
    return [resourcePath substringFromIndex:mainPath.length + 1];
  }
  return bundleName;
}

#pragma mark - Install

// +load runs once every class in the binary is registered, so the ML Kit classes are visible here.
@interface MLKResourcesLoader : NSObject
@end

@implementation MLKResourcesLoader

+ (void)load {
  Method pathMethod = class_getInstanceMethod(NSBundle.class, @selector(pathForResource:ofType:));
  MLKOriginalPathForResource = (void *)method_setImplementation(pathMethod, (IMP)MLKPathForResource);

  Class options = NSClassFromString(@"MLKCommonTextRecognizerOptions");
  Method nameMethod = options ? class_getInstanceMethod(options, @selector(bundleName)) : NULL;
  if (nameMethod) {
    MLKOriginalBundleName = (void *)method_setImplementation(nameMethod, (IMP)MLKBundleName);
  }
}

@end
