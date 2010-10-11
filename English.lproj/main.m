/* main.cpp - Secure KDE dialog for PIN entry.
   Copyright (C) 2002 Klar<E4>lvdalens Datakonsult AB
   Copyright (C) 2003 g10 Code GmbH
   Copyright (c) 2006 Benjamin Donnachie.
   Written by Steffen Hansen <steffen@klaralvdalens-datakonsult.se>.
   Modified by Marcus Brinkmann <marcus@g10code.de>.
   Adapted / rewritten by Benjamin Donnachie <benjamin@py-soft.co.uk>
     for MacOS X.
   
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

#define VERSION "0.001"

#import <Cocoa/Cocoa.h>
#include "pinentry.h"
#include "PinentryController.h"

int main(int argc, char *argv[])
{
  pinentry_init ("pinentry-mac");
  
  /* Consumes all arguments.  */
  if (pinentry_parse_opts (argc, argv))
    {
      printf ("pinentry-mac (pinentry) " VERSION "\n");
      exit (EXIT_SUCCESS);
    }

  if (pinentry_loop ())
    return 1;

  return 0;
	
}

static int
mac_cmd_handler (pinentry_t pe)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  PinentryController *pinentry;
  
  [NSApplication sharedApplication];
  [NSBundle loadNibNamed:@"MainMenu" owner:NSApp];
  pinentry = [PinentryController cInstance];
  
  [[pinentry window] center];
  
  if (pe -> grab == 1)
	{
      [NSApp activateIgnoringOtherApps: YES];
	  [[pinentry window] makeKeyAndOrderFront: pinentry];
	}
  else
    {
      [NSApp requestUserAttention: NSCriticalRequest];
	}

	char converted_description[pe->description ? strlen(pe->description) : 0];
	
	if (pe->description)
	{
		int i, j;
		
		for (i=0, j=0; i<strlen(pe->description)+1; i++, j++)
		{
			if ('\\' == pe->description[i])
				if ('n' == pe->description[i+1])
				{
					converted_description[j] = '\n';
					i++;
					continue;
				}
			converted_description[j] = pe->description[i];
		}
	}
	
  if (!!pe->pin)	// want_pass.
    {
	  if (pe -> prompt)
		[pinentry setInfoText: [NSString stringWithUTF8String:(char *) (pe->prompt)]];
	  if (pe -> description)
		[pinentry setInstructionText: [NSString stringWithUTF8String:(char *) (converted_description)]];
      if (pe->ok)
		[pinentry setOKText: [NSString stringWithUTF8String:(char *) (pe->ok)]];
      if (pe->cancel)
		[pinentry setCancelText: [NSString stringWithUTF8String:(char *) (pe->cancel)]];
	  if (pe->error)
		[pinentry setErrorText: [NSString stringWithUTF8String:(char *) (pe->error)]];
	
	  [NSApp run];
//	  [NSApp hide: pinentry];
		
	  if (![pinentry OKpressed])
	  {
		return -1;
		[pool release];
	  }

	  char * pin = (char *) [[pinentry getPINField] UTF8String];
	  if (!pin)
	  {
	    return -1;
		[pool release];
	  }
	  int len = strlen (pin);
	  if (len >= 0)
	  	{
		  pinentry_setbufferlen (pe, len + 1);
		  if (pe->pin)
			{
			  strcpy (pe->pin, pin);
//			  secmem_free (pin);
//			  [pinentry DestroyPIN];
			  [pool release];
			  return len;
			}
		}
	}
  else
	{
	  NSString *description;

	  [pinentry setConfirmMode: YES];
      if (pe->description)
        description = [NSString stringWithUTF8String:(char *) (converted_description)];
      else
        description = @"Confirm";
      [pinentry setInstructionText: description];
	  [pinentry setOKText: (pe->ok ? [NSString stringWithUTF8String:(char *) (pe->ok)] : @"OK")];
	  if (pe->one_button)
		[pinentry setCancelText: NULL];
	  else
		[pinentry setCancelText: (pe->cancel ? [NSString stringWithUTF8String:(char *) (pe->cancel)] : @"Cancel")];
		
	  [NSApp run];
//	  [NSApp hide: nil];		
	  [pool release];
	  return [pinentry OKpressed];
	}

	[pool release];
	return -1; // Shouldn't get this far.
}

pinentry_cmd_handler_t pinentry_cmd_handler = mac_cmd_handler;
