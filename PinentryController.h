/* PinentryController.h - PIN entry dialogue for Mac OS.
   Copyright (C) 2006 Benjamin Donnachie
   Written by Benjamin Donnachie <benjamin@py-soft.co.uk>
   
   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.
 
   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.
 
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
   02111-1307, USA  */

#import <Cocoa/Cocoa.h>

@interface PinentryController : NSWindowController
{
 @private
    IBOutlet NSButton *CancelButton;
    IBOutlet NSTextField *InstructionBox;
    IBOutlet NSButton *OKButton;
	IBOutlet NSButton *HideTypingButton;
    IBOutlet NSSecureTextField *PINField;
	IBOutlet NSTextField *plainPINField;
    IBOutlet NSTextField *PINText;
	IBOutlet NSTextField *ErrorBox;
	bool OKpressed;
} 

//@private
- (void) setOKpressed: (bool) pressed;

//@public
- (IBAction)CancelPressedAction:(id)sender;
- (IBAction)OKPressedAction:(id)sender;
- (IBAction)HideTypingAction:(id)sender;

+ (PinentryController *) cInstance;

- (NSString *) getPINField;

- (void) init;
- (void) setConfirmMode: (bool) mode;
- (void) setInstructionText: (NSString *) NewText;
- (void) setInfoText: (NSString *) NewText;
- (void) setOKText: (NSString *) NewText;
- (void) setCancelText: (NSString *) NewText;
- (void) setErrorText: (NSString *) NewText;
- (bool) OKpressed;

@end
