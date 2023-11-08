#import "AmplitudeFlutterPlugin.h"
#import <amplitude_flutter/amplitude_flutter-Swift.h>

@implementation AmplitudeFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAmplitudeFlutterPlugin registerWithRegistrar:registrar];
}
@end
