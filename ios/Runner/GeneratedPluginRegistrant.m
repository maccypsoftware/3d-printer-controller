//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"

#if TARGET_OS_IPHONE
  #import <Flutter/Flutter.h>
  #import <flutter_push_notifications/flutter_push_notifications-Swift.h>
  #import <permission_handler/permission_handler-Swift.h>
  #import <camera/camera-Swift.h>
  #import <video_player/video_player-Swift.h>
  #import <flutter_svg/flutter_svg-Swift.h>
  #import <shared_preferences/shared_preferences-Swift.h>
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
    [FlutterPushNotificationsPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterPushNotificationsPlugin"]];
    [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
    [FLTCameraPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTCameraPlugin"]];
    [FLTVideoPlayerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTVideoPlayerPlugin"]];
    [FlutterSvgPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterSvgPlugin"]];
    [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
}

@end
