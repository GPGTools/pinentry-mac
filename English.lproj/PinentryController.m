/* PinentryController.m - PIN entry dialogue for Mac OS.
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

#import "PinentryController.h"

PinentryController *cInstance;

@implementation PinentryController : NSWindowController

+ (PinentryController *) cInstance
{
	return cInstance;
}

- (id) init
{
	self = [super init];
	cInstance = self;
	[self setOKpressed: NO];

	return self;
}

- (bool) OKpressed
{
	return OKpressed;
}

- (void) setOKpressed: (bool) pressed
{
	OKpressed = pressed;
}

- (IBAction)CancelPressedAction:(id)sender
{
	[self setOKpressed: NO];
	[NSApp stop: self];
}

- (IBAction)OKPressedAction:(id)sender
{
	[self setOKpressed: YES];
	[NSApp stop: self];
}

- (IBAction)HideTypingAction:(id)sender
{
    if([sender state])
		{ // Hide typing
         [PINField setStringValue:[plainPINField stringValue]];
         [plainPINField setStringValue:@""];
		 [plainPINField setHidden: YES];
		 [PINField setHidden: NO];
		 [PINField becomeFirstResponder];
		}
	else
		{ // Show typing
         [plainPINField setStringValue:[PINField stringValue]];
         [PINField setStringValue:@""];
		 [plainPINField setHidden: NO];
		 [PINField setHidden: YES];
		 [plainPINField becomeFirstResponder];
		}
}

- (void) setConfirmMode: (bool) mode
{
	[PINField setHidden: mode];
	[HideTypingButton setHidden: mode];
}

- (NSString *) getPINField
{
	return ([HideTypingButton state]) ? [PINField stringValue] : [plainPINField stringValue];
	
//	PINField stringValue];
}

- (void) setInstructionText: (NSString *) NewText
{
	[InstructionBox setHidden: NO];
	[InstructionBox setStringValue: NewText];
}

- (void) setErrorText: (NSString *) NewText
{
	[ErrorBox setHidden: NO];
	[ErrorBox setStringValue: NewText];
}

- (void) setInfoText: (NSString *) NewText
{
	[PINText setStringValue: NewText];
}

- (void) setOKText: (NSString *) NewText
{
	[OKButton setTitle: NewText];
}

- (void) setCancelText: (NSString *) NewText
{
	if (NewText)
		[CancelButton setTitle: NewText];
	else
		[CancelButton setTransparent:1];
}

@end
