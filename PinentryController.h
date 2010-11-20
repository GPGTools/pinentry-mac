
@class GPGDefaults;

@interface PinentryController : NSWindowController {
	IBOutlet NSWindow *window;
	IBOutlet NSButton *okButton;
	IBOutlet NSButton *cancelButton;
	
	
	GPGDefaults *gpgDefaults;
	
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
}
@property (readonly) GPGDefaults *gpgDefaults;
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


- (NSInteger)runModal;

- (IBAction)okClick:(NSButton *)sender;
- (IBAction)cancelClick:(NSButton *)sender;


@end 
