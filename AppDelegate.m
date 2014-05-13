
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
		@autoreleasepool {
		
			const char *version = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] UTF8String];
			printf("pinentry-mac (pinentry) %s \n", version);
		
		}
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
	@autoreleasepool {
	
	NSString *keychainLabel = nil;
	NSString *cacheId = nil;
	if (pe->cache_id) {
		cacheId = [NSString gpgStringWithCString:pe->cache_id];
	}
	
	// cache_id is used to save the passphrase in the Mac OS X keychain.
	if (cacheId && pe->pin) {
		if (pe->error) {
			storePassphraseInKeychain(cacheId, nil, nil);
		} else {
			const char *passphrase;
			passphrase = [getPassphraseFromKeychain(cacheId) UTF8String];
			if (passphrase) {
				int len = strlen(passphrase);
				pinentry_setbufferlen(pe, len + 1);
				if (pe->pin) {
					strcpy(pe->pin, passphrase);
					return len;
				} else {
					return -1;
				}
			}				
		}
	}
	
	
	
	PinentryController *pinentry = [[PinentryController alloc] init];
	
	pinentry.grab = pe->grab;
	
	NSString *description = nil;
	if (pe->description) {
		description = [[NSString gpgStringWithCString:pe->description] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
	}
	
	
	
	
	/*
	 PINENTRY_USER_DATA should be comma-seperated.
	*/
	NSString *userData = nil;
	const char *cUserData = getenv("PINENTRY_USER_DATA");
	if (cUserData) {
		userData = [NSString gpgStringWithCString:cUserData];
	}
	
	
	if (userData) {
		/*
		 DESCRIPTION is percent escaped and additionally can use the following placeholders:
		 %FINGERPRINT, %KEYID, %USERID, %EMAIL, %COMMENT, %NAME
		*/
		
		NSMutableString *descriptionTemplate = [[userData stringBetweenString:@"DESCRIPTION=" andString:@"," needEnd:NO] mutableCopy];
				
		if (descriptionTemplate) {
			NSString *keyID = nil;
			if (pe->cache_id) { // Get KeyID from cache_id.
				NSString *fingerprint = [NSString gpgStringWithCString:pe->cache_id];
				if (fingerprint) {
					[descriptionTemplate replaceOccurrencesOfString:@"%FINGERPRINT" withString:fingerprint options:0 range:NSMakeRange(0, descriptionTemplate.length)];
					keyID = [fingerprint substringFromIndex:fingerprint.length - 8];
					[descriptionTemplate replaceOccurrencesOfString:@"%KEYID" withString:keyID options:0 range:NSMakeRange(0, descriptionTemplate.length)];
				}
			}
			
			if (description) { //Parse original description if any, to get UserID.
				NSArray *lines = [description componentsSeparatedByString:@"\n"];
				if (lines.count > 2) {
					NSString *line = [lines objectAtIndex:1];
					
					
					NSString *userID = [line stringBetweenString:@"\"" andString:@"\"" needEnd:YES];
					NSString *email, *comment;
					
					if (userID) {
						[descriptionTemplate replaceOccurrencesOfString:@"%USERID" withString:userID options:0 range:NSMakeRange(0, descriptionTemplate.length)];
						
						NSUInteger textLength = [userID length];
						NSRange range;
						
						// Find e-mail.
						if ([userID hasSuffix:@">"] && (range = [userID rangeOfString:@" <" options:NSBackwardsSearch]).length > 0) {
							range.location += 2;
							range.length = textLength - range.location - 1;
							
							email = [userID substringWithRange:range];
							[descriptionTemplate replaceOccurrencesOfString:@"%EMAIL" withString:email options:0 range:NSMakeRange(0, descriptionTemplate.length)];
							
							userID = [userID substringToIndex:range.location - 2];
							textLength -= (range.length + 3);
						}
						
						// Find comment.
						range = [userID rangeOfString:@" (" options:NSBackwardsSearch];
						if (range.length > 0 && range.location > 0 && [userID hasSuffix:@")"]) {
							range.location += 2;
							range.length = textLength - range.location - 1;
							
							comment = [userID substringWithRange:range];
							[descriptionTemplate replaceOccurrencesOfString:@"%COMMENT" withString:comment options:0 range:NSMakeRange(0, descriptionTemplate.length)];
							
							userID = [userID substringToIndex:range.location - 2];
						}
						
						// Now, userID only contains the name.
						[descriptionTemplate replaceOccurrencesOfString:@"%NAME" withString:userID options:0 range:NSMakeRange(0, descriptionTemplate.length)];
						
						keychainLabel = [NSString stringWithFormat:@"%@ <%@> (%@)", userID, email ? email : @"", keyID ? keyID : @""];
					}
				}
			}
			
			description = [descriptionTemplate stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		}
		
		NSString *iconPath = [userData stringBetweenString:@"ICON=" andString:@"," needEnd:NO];
		
		if (iconPath.length > 0) {
			NSImage *icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
			pinentry.icon = icon;
			[NSApp setApplicationIconImage:icon];
		}
	}
	
	
	if (pe->pin) { // want_pass.
		if (pe->prompt)
			pinentry.promptText = [NSString gpgStringWithCString:pe->prompt];
		if (description)
			pinentry.descriptionText = description;
		if (pe->ok)
			pinentry.okButtonText = [NSString gpgStringWithCString:pe->ok];
		if (pe->cancel)
			pinentry.cancelButtonText = [NSString gpgStringWithCString:pe->cancel];
		if (pe->error)
			pinentry.errorText = [NSString gpgStringWithCString:pe->error];
		if (pe->cache_id)
			pinentry.canUseKeychain = YES;
		
		
		if (![pinentry runModal]) {
			return -1;
		}
		
		
		const char *passphrase = [pinentry.passphrase ? pinentry.passphrase : @"" UTF8String];
		if (!passphrase) {
			return -1;
		}
		
		if (pinentry.saveInKeychain && cacheId) {
			storePassphraseInKeychain(cacheId, pinentry.passphrase, keychainLabel);
		}
		
		
		int len = strlen(passphrase);
		pinentry_setbufferlen(pe, len + 1);
		if (pe->pin) {
			strcpy(pe->pin, passphrase);
			return len;
		}
	} else {
		pinentry.confirmMode = YES;
		pinentry.descriptionText = description ? description : @"Confirm";
		pinentry.okButtonText = pe->ok ? [NSString gpgStringWithCString:pe->ok] : nil;
		pinentry.cancelButtonText = pe->cancel ? [NSString gpgStringWithCString:pe->cancel] : nil;
		pinentry.oneButton = pe->one_button;
		
		NSInteger retVal = [pinentry runModal];
		
		return retVal;
	}
	
	
	return -1; // Shouldn't get this far.
	}
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



@implementation NSString (BetweenExtension)
- (NSString *)stringBetweenString:(NSString *)start andString:(NSString *)end needEnd:(BOOL)endNeeded {
	NSRange range = [self rangeOfString:start];
	NSUInteger location;
	
	if (range.location == NSNotFound) {
		return nil;
	}
	
	location = range.location + range.length;
	range = [self rangeOfString:end options:NSCaseInsensitiveSearch range:NSMakeRange(location, self.length - location)];
	
	if (range.location != NSNotFound) {
		range.length = range.location - location;
	} else {
		if (endNeeded) {
			return nil;
		}
		range.length = self.length - location;
	}
	range.location = location;
	
	return [self substringWithRange:range];
}
@end

@implementation NSString (gpgString)
+ (NSString *)gpgStringWithCString:(const char *)cString {
	if (!cString) {
		return @"";
	}
	
	unsigned long length = strlen(cString);
	
	if (length == 0) {
		return @"";
	}

	NSString *retString = [NSString stringWithUTF8String:cString];
	if (retString) {
		return retString;
	}
	
	
	// Löschen aller ungültigen Zeichen, damit die umwandlung nach UTF-8 funktioniert.
	const uint8_t *inText = (uint8_t *)cString;
	
	NSUInteger i = 0, c = length;
	
	uint8_t *outText = malloc(c + 1);
	if (outText) {
		uint8_t *outPos = outText;
		const uint8_t *startChar = nil;
		int multiByte = 0;
		
		for (; i < c; i++) {
			if (multiByte && (*inText & 0xC0) == 0x80) { // Fortsetzung eines Mehrbytezeichen
				multiByte--;
				if (multiByte == 0) {
					while (startChar <= inText) {
						*(outPos++) = *(startChar++);
					}
				}
			} else if ((*inText & 0x80) == 0) { // Normales ASCII Zeichen.
				*(outPos++) = *inText;
				multiByte = 0;
			} else if ((*inText & 0xC0) == 0xC0) { // Beginn eines Mehrbytezeichen.
				if (multiByte) {
					*(outPos++) = '?';
				}
				if (*inText <= 0xDF && *inText >= 0xC2) {
					multiByte = 1;
					startChar = inText;
				} else if (*inText <= 0xEF && *inText >= 0xE0) {
					multiByte = 2;
					startChar = inText;
				} else if (*inText <= 0xF4 && *inText >= 0xF0) {
					multiByte = 3;
					startChar = inText;
				} else {
					*(outPos++) = '?';
					multiByte = 0;
				}
			} else {
				*(outPos++) = '?';
			}
			
			inText++;
		}
		*outPos = 0;
		
		
		retString = [NSString gpgStringWithCString:(char *)outText];
		
		free(outText);
		if (retString) {
			return retString;
		}
	}
	// Ende der Säuberung.
	
	
	
	int encodings[3] = {NSISOLatin1StringEncoding, NSISOLatin2StringEncoding, NSASCIIStringEncoding};
	for(i = 0; i < 3; i++) {
		retString = [NSString stringWithCString:cString encoding:encodings[i]];
		if (retString.length > 0) {
			return retString;
		}
	}
	
	return retString;
}
@end
