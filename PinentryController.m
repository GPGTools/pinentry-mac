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

#import "PinentryController.h"
#import "GPGDefaults.h"

@interface PinentryController (Private)
- (void)updateButtonSizes;
@end


@implementation PinentryController : NSWindowController
@synthesize descriptionText, promptText, errorText, passphrase, grab, confirmMode, oneButton, saveInKeychain, canUseKeychain, showType;

PinentryController *_sharedInstance = nil;

- (id)init {
	self = [super init];
	
	
	descriptionText = nil;
	promptText = nil;
	errorText = nil;
	passphrase = nil;
	okButtonText = nil;
	cancelButtonText = nil;
	
	confirmMode = NO;
	oneButton = NO;
	okPressed = NO;
	canUseKeychain = NO;
	
	showType = [[GPGDefaults gpgDefaults] boolForKey:@"ShowPassphrase"];
	saveInKeychain = [[GPGDefaults gpgDefaults] boolForKey:@"UseKeychain"];

	[NSBundle loadNibNamed:@"Pinentry" owner:self];
	
	
	return self;	
}
- (NSInteger)runModal {
	[window center];
	 
	[NSApp activateIgnoringOtherApps:YES];
	[window makeKeyAndOrderFront:self];
	
	[window makeFirstResponder:securePassphraseField];
	
	[NSApp runModalForWindow:window];
	return okPressed;
}



- (IBAction)okClick:(NSButton *)sender {
	okPressed = YES;
	[window close];
}
- (IBAction)cancelClick:(NSButton *)sender {
	[window close];
}



// Button properties

- (void)setOkButtonText:(NSString *)value {
	if (value != okButtonText) {
		[okButtonText release];
		okButtonText = [value retain];
		[self updateButtonSizes];
	}
}
- (NSString *)okButtonText {
	return okButtonText;
}
- (void)setCancelButtonText:(NSString *)value {
	if (value != cancelButtonText) {
		[cancelButtonText release];
		cancelButtonText = [value retain];
		[self updateButtonSizes];
	}	
}
- (NSString *)cancelButtonText {
	return cancelButtonText;
}

- (void)updateButtonSizes {
	float windowWidth = [window contentRectForFrameRect:[window frame]].size.width;
	NSDictionary *fontAttributes = [NSDictionary dictionaryWithObject:[NSFont messageFontOfSize:0] forKey:NSFontAttributeName];
	float okButtonWidth, cancelButtonWidth;
	
	if (okButtonText) {
		okButtonWidth = [okButtonText sizeWithAttributes:fontAttributes].width + 40;
	} else {
		okButtonWidth = 110;
	}
	
	if (cancelButtonText) {
		cancelButtonWidth = [cancelButtonText sizeWithAttributes:fontAttributes].width + 40;
	} else {
		cancelButtonWidth = 110;
	}
	
	
	double maxButtonSpace = [window contentRectForFrameRect:[window frame]].size.width;
	maxButtonSpace -= [showTypingButton frame].size.width;
	maxButtonSpace -= 30;
	
	if (okButtonWidth + cancelButtonWidth > maxButtonSpace) {
		float sum = okButtonWidth + cancelButtonWidth - maxButtonSpace;
		float ratio = okButtonWidth / cancelButtonWidth;
		okButtonWidth -= sum * ratio / 2;
		cancelButtonWidth -= sum * (1 / ratio) / 2;
	}
	
	
	NSRect okButtonRect = [okButton frame];
	NSRect cancelButtonRect = [cancelButton frame];
	
	okButtonRect.size.width = okButtonWidth;
	okButtonRect.origin.x = windowWidth - okButtonWidth - 14;
	
	cancelButtonRect.size.width = cancelButtonWidth;
	cancelButtonRect.origin.x = windowWidth - cancelButtonWidth - okButtonWidth - 14;
	
	
	[okButton setFrame:okButtonRect];
	[cancelButton setFrame:cancelButtonRect];
	[okButton setNeedsDisplay:YES];
	[cancelButton setNeedsDisplay:YES];
}


// Window Controller

- (void)windowWillClose:(NSNotification *)notification {
	[NSApp stopModal];
}
- (void)setWindow:(NSWindow *)newWindow {
	window = newWindow;
	window.level = 30;
}
- (NSWindow *)window {
	return window;
}

@end
