/*
 Copyright � Roman Zechmeister, 2010
 
 Dieses Programm ist freie Software. Sie k�nnen es unter den Bedingungen 
 der GNU General Public License, wie von der Free Software Foundation 
 ver�ffentlicht, weitergeben und/oder modifizieren, entweder gem�� 
 Version 3 der Lizenz oder (nach Ihrer Option) jeder sp�teren Version.
 
 Die Ver�ffentlichung dieses Programms erfolgt in der Hoffnung, da� es Ihnen 
 von Nutzen sein wird, aber ohne irgendeine Garantie, sogar ohne die implizite 
 Garantie der Marktreife oder der Verwendbarkeit f�r einen bestimmten Zweck. 
 Details finden Sie in der GNU General Public License.
 
 Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem 
 Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>.
*/


@interface PinentryController : NSWindowController {
	IBOutlet NSWindow *window;
	IBOutlet NSButton *okButton;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *showTypingButton;
	
	
	NSString *descriptionText;
	NSString *promptText;
	NSString *errorText;
	NSString *passphrase;
	
	NSString *okButtonText;
	NSString *cancelButtonText;
	
	NSImage *_icon;

	BOOL grab;
	BOOL confirmMode;
	BOOL oneButton;
	BOOL okPressed;
	BOOL saveInKeychain;
	BOOL canUseKeychain;
	BOOL showType;
	
	IBOutlet NSTextField *passphraseField;
	IBOutlet NSTextField *securePassphraseField;	
}
@property (nonatomic, unsafe_unretained) NSWindow *window;

@property (nonatomic, strong) NSString *descriptionText, *promptText, *errorText, *passphrase, *okButtonText, *cancelButtonText;
@property (nonatomic) BOOL grab, confirmMode, oneButton, saveInKeychain, canUseKeychain, showType;
@property (nonatomic, strong) NSImage *icon;


- (NSInteger)runModal;

- (IBAction)okClick:(NSButton *)sender;
- (IBAction)cancelClick:(NSButton *)sender;


@end 
