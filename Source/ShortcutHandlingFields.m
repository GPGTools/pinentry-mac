/*
 Copyright © Moritz Ulrich, 2011
 
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


#import "ShortcutHandlingFields.h"

@implementation ShortcutHandlingTextField

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) {
        // The command key is the ONLY modifier key being pressed.
        if ([[event charactersIgnoringModifiers] isEqualToString:@"x"]) {
            return [NSApp sendAction:@selector(cut:) to:[[self window] firstResponder] from:self];
        } else if ([[event charactersIgnoringModifiers] isEqualToString:@"c"]) {
            return [NSApp sendAction:@selector(copy:) to:[[self window] firstResponder] from:self];
        } else if ([[event charactersIgnoringModifiers] isEqualToString:@"v"]) {
            return [NSApp sendAction:@selector(paste:) to:[[self window] firstResponder] from:self];
        } else if ([[event charactersIgnoringModifiers] isEqualToString:@"a"]) {
            return [NSApp sendAction:@selector(selectAll:) to:[[self window] firstResponder] from:self];
        }
    }
    return [super performKeyEquivalent:event];
}

@end

@implementation ShortcutHandlingSecureTextField

- (BOOL)performKeyEquivalent:(NSEvent*)event {
    if(([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) 
    {
        if ([[event charactersIgnoringModifiers] isEqualToString:@"v"]) 
        {
            return [NSApp sendAction:@selector(paste:) 
                                  to:[[self window] firstResponder] from:self];
        } 
        else if([[event charactersIgnoringModifiers] isEqualToString:@"a"]) 
        {
            return [NSApp sendAction:@selector(selectAll:) 
                                  to:[[self window] firstResponder] from:self];
        }
    }
    return [super performKeyEquivalent:event];
}

@end

