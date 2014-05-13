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



int main(int argc, char *argv[]) {
#ifdef CODE_SIGN_CHECK
	@autoreleasepool {
	/* Check the validity of the code signature. */
    if (!isBundleValidSigned([NSBundle mainBundle])) {
		NSRunAlertPanel(@"Someone tampered with your installation of pinentry-mac!", @"To keep you safe, pinentry-mac will exit now!\n\nPlease download and install the latest version of GPG Suite from https://gpgtools.org to be sure you have an original version from us!", nil, nil, nil);
        return 1;
    }
	}
#endif
	
	return NSApplicationMain(argc,  (const char **) argv);
}

