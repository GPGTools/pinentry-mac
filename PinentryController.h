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

	BOOL grab;
	BOOL confirmMode;
	BOOL oneButton;
	BOOL okPressed;
	BOOL saveInKeychain;
	BOOL canUseKeychain;
	BOOL showType;
}
@property (assign) NSWindow *window;
@property (retain) NSString *descriptionText;
@property (retain) NSString *promptText;
@property (retain) NSString *errorText;
@property (retain) NSString *passphrase;
@property (retain) NSString *okButtonText;
@property (retain) NSString *cancelButtonText;
@property BOOL grab;
@property BOOL confirmMode;
@property BOOL oneButton;
@property BOOL saveInKeychain;
@property BOOL canUseKeychain;
@property BOOL showType;


- (NSInteger)runModal;

- (IBAction)okClick:(NSButton *)sender;
- (IBAction)cancelClick:(NSButton *)sender;


@end 
