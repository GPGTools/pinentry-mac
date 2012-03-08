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

void storePassphraseInKeychain(const char *key, const char *passphrase) {
	int status;
	SecKeychainItemRef itemRef = NULL;
	SecKeychainRef keychainRef = NULL;
	
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
	
	status = SecKeychainFindGenericPassword (keychainRef, strlen(GPG_SERVICE_NAME), GPG_SERVICE_NAME, 
											 strlen(key), key, NULL, NULL, &itemRef);
	if (status == 0) {
		if (passphrase) {
			SecKeychainItemModifyAttributesAndData (itemRef, NULL, strlen(passphrase), passphrase);
		} else {
			SecKeychainItemDelete(itemRef);
		}
		CFRelease(itemRef);
	} else {
		if (passphrase) {
			SecKeychainAddGenericPassword (keychainRef, strlen(GPG_SERVICE_NAME), GPG_SERVICE_NAME, 
										   strlen(key), key, strlen(passphrase), passphrase, NULL);
		}
	}
	CFRelease(keychainRef);
}

char* getPassphraseFromKeychain(const char *key) {
	int status;
	char *passphrase;
	UInt32 passphraseLength;
	void *passphraseData = NULL;
	SecKeychainRef keychainRef = NULL;
	
    NSString *keychainPath = [[GPGDefaults gpgDefaults] valueForKey:@"KeychainPath"];
    const char* path = [keychainPath UTF8String];
    
    if(keychainPath && [keychainPath length]) {
        if(SecKeychainOpen(path, &keychainRef) != 0)
            return NULL;
    }
    /*else if(SecKeychainCopyDefault(&keychainRef) != 0) {
        return NULL;
    }*/
	
	status = SecKeychainFindGenericPassword (keychainRef, strlen(GPG_SERVICE_NAME), GPG_SERVICE_NAME, 
											 strlen(key), key, &passphraseLength, &passphraseData, NULL);
	if (keychainRef) CFRelease(keychainRef);
	
	if (status != 0) {
		return NULL;
	}
	
	passphrase = malloc(passphraseLength + 1);
	passphrase[passphraseLength] = 0;
	memcpy(passphrase, passphraseData, passphraseLength);
	
	SecKeychainItemFreeContent(NULL, passphraseData);
	
	return passphrase;
}

