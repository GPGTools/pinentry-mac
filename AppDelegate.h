#import <Cocoa/Cocoa.h>

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
@interface AppDelegate : NSObject
#else
@interface AppDelegate : NSObject <NSApplicationDelegate>
#endif

@end
