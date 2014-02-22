#import "PassphraseLengthFormatter.h"
#import <Cocoa/Cocoa.h>

@implementation PassphraseLengthFormatter

- (NSString *)stringForObjectValue:(id)object {
	return object;
}

- (BOOL)getObjectValue:(id *)object forString:(NSString *)string errorDescription:(NSString **)error {
	*object = string;
	return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error {
	if (partialString.length > 300) {
		*newString = [partialString substringToIndex:300];
		return NO;
	}
	return YES;
}

@end
