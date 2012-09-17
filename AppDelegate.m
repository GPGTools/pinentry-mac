
#import "AppDelegate.h"
#include "pinentry.h"
#include "PinentryController.h"
#import "GPGDefaults.h"
#import "KeychainSupport.h"
#ifdef FALLBACK_CURSES
#include <pinentry-curses.h>
#endif



extern int *_NSGetArgc(void);
extern char ***_NSGetArgv(void);




@implementation AppDelegate

static int mac_cmd_handler (pinentry_t pe);
pinentry_cmd_handler_t pinentry_cmd_handler = mac_cmd_handler;

#ifdef FALLBACK_CURSES
int pinentry_mac_is_curses_demanded();
#endif




- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	pinentry_init("pinentry-mac");
	
#ifdef FALLBACK_CURSES
    if (pinentry_mac_is_curses_demanded())
        pinentry_cmd_handler = curses_cmd_handler;
#endif
    
	/* Consumes all arguments.  */
	
	if (pinentry_parse_opts(*_NSGetArgc(), *_NSGetArgv())) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		const char *version = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] UTF8String];
		printf("pinentry-mac (pinentry) %s \n", version);
		
		[pool drain];
		exit(0);
    }
	
	//dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	
	//dispatch_async(queue, ^{
	if (pinentry_loop()) {
		exit(1);
	}
	exit(0);
	//});
}



static int mac_cmd_handler (pinentry_t pe) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (pe->cache_id && pe->pin) {
		
		if (pe->error) {
			storePassphraseInKeychain(pe->cache_id, nil);
		} else {
			char *passphrase;
			passphrase = getPassphraseFromKeychain(pe->cache_id);
			if (passphrase) {
				int len = strlen(passphrase);
				pinentry_setbufferlen(pe, len + 1);
				if (pe->pin) {
					strcpy(pe->pin, passphrase);
					[pool drain];
					return len;
				} else {
					[pool drain];
					return -1;
				}
			}				
		}
	}
	
	
	PinentryController *pinentry = [[[PinentryController alloc] init] autorelease];
	
	pinentry.grab = pe->grab;
	
	NSString *description = nil;
	if (pe->description) {
		description = [[NSString stringWithUTF8String:pe->description] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
	}
	
	if (pe->pin) { // want_pass.
		if (pe->prompt)
			pinentry.promptText = [NSString stringWithUTF8String:pe->prompt];
		if (description)
			pinentry.descriptionText = description;
		if (pe->ok)
			pinentry.okButtonText = [NSString stringWithUTF8String:pe->ok];
		if (pe->cancel)
			pinentry.cancelButtonText = [NSString stringWithUTF8String:pe->cancel];
		if (pe->error)
			pinentry.errorText = [NSString stringWithUTF8String:pe->error];
		if (pe->cache_id)
			pinentry.canUseKeychain = YES;
		
		
		if (![pinentry runModal]) {
			[pool drain];
			return -1;
		}
		
		
		const char *passphrase = [pinentry.passphrase ? pinentry.passphrase : @"" UTF8String];
		if (!passphrase) {
			[pool drain];
			return -1;
		}
		
		if (pinentry.saveInKeychain && pe->cache_id) {
			storePassphraseInKeychain(pe->cache_id, passphrase);
		}
		
		
		int len = strlen(passphrase);
		pinentry_setbufferlen(pe, len + 1);
		if (pe->pin) {
			strcpy(pe->pin, passphrase);
			[pool drain];
			return len;
		}
	} else {
		pinentry.confirmMode = YES;
		pinentry.descriptionText = description ? description : @"Confirm";
		pinentry.okButtonText = pe->ok ? [NSString stringWithUTF8String:pe->ok] : nil;
		pinentry.cancelButtonText = pe->cancel ? [NSString stringWithUTF8String:pe->cancel] : nil;
		pinentry.oneButton = pe->one_button;
		
		NSInteger retVal = [pinentry runModal];
		
		[pool drain];
		return retVal;
	}
	
	[pool drain];
	return -1; // Shouldn't get this far.
}

#ifdef FALLBACK_CURSES
/* On Mac, the DISPLAY environment variable, which is passed from 
 a session to gpg2 to gpg-agent to pinentry and which is used
 on other platforms for falling back to curses, is not completely
 reliable, since some Mac users do not use X11. 
 
 It might be valuable to submit patches so that gpg-agent could
 automatically indicate the state of SSH_CONNECTION to pinentry,
 which would be useful for OS X.
 
 This pinentry-mac handling will recognize USE_CURSES=1 in
 the environment variable PINENTRY_USER_DATA (which is 
 automatically passed from session to gpg2 to gpg-agent to
 pinentry) to allow the user to specify that curses should be 
 initialized. 
 
 E.g. in .bashrc or .profile:
 
 if test "$SSH_CONNECTION" != ""
 then
 export PINENTRY_USER_DATA="USE_CURSES=1"
 fi
 */
int pinentry_mac_is_curses_demanded() {
    const char *s;
    
    s = getenv ("PINENTRY_USER_DATA");
    if (s && *s) {
        return (strstr(s, "USE_CURSES=1") != NULL);
    }
    return 0;
}
#endif



@end
