/*
 Copyright © Roman Zechmeister, 2010
 
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

#import <Security/Security.h>
#import "GPGDefaults.h"
#import "KeychainSupport.h"

#define GPG_SERVICE_NAME "GnuPG"

void storePassphraseInKeychain(NSString *fingerprint, NSString *passphrase, NSString *label) {
	int status;
	SecKeychainItemRef itemRef = nil;
	SecKeychainRef keychainRef = nil;
	
    NSString *keychainPath = [[GPGDefaults gpgDefaults] valueForKey:@"KeychainPath"];
    const char* path = [keychainPath UTF8String];
    
    if(keychainPath && [keychainPath length]) {
        if(SecKeychainOpen(path, &keychainRef) != 0) {
            return;
        }
    }
    else if(SecKeychainCopyDefault(&keychainRef) != 0) {
        return;
    }
	
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								kSecClassGenericPassword, kSecClass,
								@GPG_SERVICE_NAME, kSecAttrService,
								fingerprint, kSecAttrAccount,
								kCFBooleanTrue, kSecReturnRef,
								keychainRef, kSecUseKeychain,
								nil];

	status = SecItemCopyMatching((CFDictionaryRef)attributes, (CFTypeRef *)&itemRef);
	
	
	if (status == 0) {
		if (passphrase) {
			SecKeychainItemModifyAttributesAndData (itemRef, nil, [passphrase lengthOfBytesUsingEncoding:NSUTF8StringEncoding], [passphrase UTF8String]);
		} else {
			SecKeychainItemDelete(itemRef);
		}
		CFRelease(itemRef);
	} else {
		if (passphrase) {
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
										kSecClassGenericPassword, kSecClass,
										@GPG_SERVICE_NAME, kSecAttrService,
										fingerprint, kSecAttrAccount,
										[passphrase dataUsingEncoding:NSUTF8StringEncoding], kSecValueData,
										label ? label : @GPG_SERVICE_NAME, kSecAttrLabel,
										keychainRef, kSecUseKeychain,
										nil];
			
			SecItemAdd((CFDictionaryRef)attributes, nil);
		}
	}
	CFRelease(keychainRef);
}

NSString *getPassphraseFromKeychain(NSString *fingerprint) {
	int status;
	SecKeychainRef keychainRef = nil;
	
    NSString *keychainPath = [[GPGDefaults gpgDefaults] valueForKey:@"KeychainPath"];
    const char* path = [keychainPath UTF8String];
    
    if(keychainPath && [keychainPath length]) {
        if(SecKeychainOpen(path, &keychainRef) != 0)
            return nil;
    }

	
	
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								kSecClassGenericPassword, kSecClass,
								@GPG_SERVICE_NAME, kSecAttrService,
								fingerprint, kSecAttrAccount,
								kCFBooleanTrue, kSecReturnData,
								keychainRef, kSecUseKeychain,
								nil];
	
	NSData *passphraseData = nil;
	status = SecItemCopyMatching((CFDictionaryRef)attributes, (CFTypeRef *)&passphraseData);
	
	
	if (keychainRef) CFRelease(keychainRef);
	
	if (status != 0) {
		return nil;
	}
	
	
	NSString *passphrase = [[[NSString alloc] initWithData:passphraseData encoding:NSUTF8StringEncoding] autorelease];
	CFRelease(passphraseData);
	
	return passphrase;
}

