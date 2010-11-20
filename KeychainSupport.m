
#import <Security/Security.h>
#import "KeychainSupport.h"

#define GPG_SERVICE_NAME "GnuPG"

void storePassphraseInKeychain(const char *key, const char *passphrase) {
	int status;
	SecKeychainItemRef itemRef = NULL;
	SecKeychainRef keychainRef = NULL;
	
	if (SecKeychainCopyDefault(&keychainRef) != 0) {
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
	
	if (SecKeychainCopyDefault(&keychainRef) != 0) {
		return NULL;
	}
	
	status = SecKeychainFindGenericPassword (keychainRef, strlen(GPG_SERVICE_NAME), GPG_SERVICE_NAME, 
											 strlen(key), key, &passphraseLength, &passphraseData, NULL);
	CFRelease(keychainRef);
	
	if (status != 0) {
		return NULL;
	}
	
	passphrase = malloc(passphraseLength + 1);
	passphrase[passphraseLength] = 0;
	memcpy(passphrase, passphraseData, passphraseLength);
	
	SecKeychainItemFreeContent(NULL, passphraseData);
	
	return passphrase;
}

