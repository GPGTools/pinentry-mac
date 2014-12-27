#import "PassphraseLengthFormatter.h"
#import <Cocoa/Cocoa.h>

#define MAX_PASSPHRASE_LENGTH 300

@implementation PassphraseLengthFormatter

- (NSString *)stringForObjectValue:(id)object {
    if(![object isKindOfClass:[NSString class]])
        return nil;

    return [NSString stringWithString:object];
}

- (BOOL)getObjectValue:(id *)object forString:(NSString *)string errorDescription:(NSString **)error {
	// Generate a new string here, otherwise bindings won't work properly.
    *object = [NSString stringWithString:string];
	return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error {
    // Code found on http://stackoverflow.com/a/19635242 which seems to work properly and as expected.

    NSString *proposedString = *partialStringPtr;
    if([proposedString length] <= MAX_PASSPHRASE_LENGTH)
        return YES;

    *partialStringPtr = [NSString stringWithString:[proposedString substringToIndex:MAX_PASSPHRASE_LENGTH]];
    return NO;
}

@end
