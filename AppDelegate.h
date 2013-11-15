#import <Cocoa/Cocoa.h>

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
@interface AppDelegate : NSObject
#else
@interface AppDelegate : NSObject <NSApplicationDelegate>
#endif

@end

@interface NSString (BetweenExtension)
- (NSString *)stringBetweenString:(NSString *)start andString:(NSString *)end needEnd:(BOOL)endNeeded;
@end

@interface NSString (gpgString)
+ (NSString *)gpgStringWithCString:(const char *)cString;
@end

