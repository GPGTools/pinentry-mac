/* main.m - Secure dialog for PIN entry.
 Copyright (C) 2002 Klar<E4>lvdalens Datakonsult AB
 Copyright (C) 2003 g10 Code GmbH
 Copyright (c) 2006 Benjamin Donnachie.
 Copyright (C) 2010 Roman Zechmeister
 Written by Steffen Hansen <steffen@klaralvdalens-datakonsult.se>.
 Modified by Marcus Brinkmann <marcus@g10code.de>.
 Adapted / rewritten by Benjamin Donnachie <benjamin@py-soft.co.uk> for MacOS X.
 Modified by Roman Zechmeister <Roman.Zechmeister@aon.at>
 
 Code Signature verification added by Lukas Pitschl <lukele@leftandleaving.com>
 
 Dieses Programm ist freie Software. Sie können es unter den Bedingungen 
 der GNU General Public License, wie von der Free Software Foundation 
 veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß 
 Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.
 
 Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen 
 von Nutzen sein wird, aber ohne irgendeine Garantie, sogar ohne die implizite 
 Garantie der Marktreife oder der Verwendbarkeit für einen bestimmten Zweck. 
 Details finden Sie in der GNU General Public License.
 
 Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem 
 Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>.
*/



#import <Cocoa/Cocoa.h>
#import "pinentry.h"

extern pinentry_cmd_handler_t pinentry_cmd_handler;

BOOL isBundleValidSigned(NSBundle *bundle) {
	SecRequirementRef requirement = nil;
    SecStaticCodeRef staticCode = nil;
	
    SecStaticCodeCreateWithPath((__bridge CFURLRef)[bundle bundleURL], 0, &staticCode);
	SecRequirementCreateWithString(CFSTR("anchor apple generic and cert leaf = H\"233B4E43187B51BF7D6711053DD652DDF54B43BE\""), 0, &requirement);
	
	OSStatus result = SecStaticCodeCheckValidity(staticCode, 0, requirement);
    
    if (staticCode) CFRelease(staticCode);
    if (requirement) CFRelease(requirement);
    return result == noErr;
}


#ifdef FALLBACK_CURSES
#import "pinentry-curses.h"

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




int main(int argc, char *argv[]) {
	@autoreleasepool {
		usleep(100000);
#ifdef CODE_SIGN_CHECK
		/* Check the validity of the code signature. */
		if (!isBundleValidSigned([NSBundle mainBundle])) {
			NSRunAlertPanel(@"Someone tampered with your installation of pinentry-mac!", @"To keep you safe, pinentry-mac will exit now!\n\nPlease download and install the latest version of GPG Suite from https://gpgtools.org to be sure you have an original version from us!", nil, nil, nil);
			return 1;
		}
#endif
		
		pinentry_init("pinentry-mac");
		
		
		pinentry_parse_opts(argc, argv);
		
		/* Consumes all arguments.  */
		if (false) {
			const char *version = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] UTF8String];
			printf("pinentry-mac (pinentry) %s \n", version);
			return 0;
		}
		
		
		
#ifdef FALLBACK_CURSES
		if (pinentry_mac_is_curses_demanded()) {
			// Only load the curses interface.
			pinentry_cmd_handler = curses_cmd_handler;
			if (pinentry_loop()) {
				return 1;
			}
			return 0;
		}
#endif
		
		// Load GUI.
		return NSApplicationMain(argc, (const char **)argv);
	}
}

