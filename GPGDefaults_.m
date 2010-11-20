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

#import "GPGDefaults.h"

NSString *gpgDefaultsDomain = @"org.gpgtools.common";
NSString *GPGDefaultsUpdatedNotification = @"org.gpgtools.GPGDefaultsUpdatedNotification";

@interface GPGDefaults (Private)
- (void)refreshDefaults;
- (NSMutableDictionary *)defaults;
- (void)writeToDisk;
- (void)defaultsDidUpdated:(NSNotification *)notification;
@end


@implementation GPGDefaults

- (id)init {
	if (self = [super init]) {
		_defaults = nil;
		_defaultsLock = [[NSLock alloc] init];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsDidUpdated:) name:GPGDefaultsUpdatedNotification object:nil];
		self.domain = gpgDefaultsDomain;
	}
	return self;
}

- (void)setDomain:(NSString *)value {
	if (value != _domain) {
		NSString *old = _domain;
		_domain = [value retain];
		[old release];
	}
}
- (NSString *)domain {
	return _domain;
}

- (void)setObject:(id)value forKey:(NSString *)defaultName {
	[_defaultsLock lock];
	[self.defaults setObject:value forKey:defaultName];
	[_defaultsLock unlock];
	[self writeToDisk];
}
- (id)objectForKey:(NSString *)defaultName {
	[_defaultsLock lock];
	NSDictionary *dict = self.defaults;
	NSObject *obj = [dict objectForKey:defaultName];
	[_defaultsLock unlock];
	return obj;
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName {
	[self setObject:[NSNumber numberWithBool:value] forKey:defaultName];
}
- (BOOL)boolForKey:(NSString *)defaultName {
	return [[self objectForKey:defaultName] boolValue];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	[self setObject:value forKey:key];
}
- (id)valueForUndefinedKey:(NSString *)key {
	return [self objectForKey:key];
}


//Private


- (void)refreshDefaults {
	NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName:_domain];
	NSMutableDictionary *old = _defaults;
	if (dictionary) {
		_defaults = [[dictionary mutableCopy] retain];
	} else {
		_defaults = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
	[old release];
}

- (NSMutableDictionary *)defaults {
	if (!_defaults) {
		[self refreshDefaults];
	}
	return [[_defaults retain] autorelease];
}

- (void)writeToDisk {
	[_defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:self.defaults forName:_domain];
	[_defaultsLock unlock];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:_domain, @"domain", [NSNumber numberWithInteger:(NSInteger)self], @"sender", nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GPGDefaultsUpdatedNotification object:@"org.gpgtools.GPGDefaults" userInfo:userInfo];
}

- (void)defaultsDidUpdated:(NSNotification *)notification {
	NSDictionary *userInfo = [notification userInfo];
	if ([[userInfo objectForKey:@"sender"] integerValue] != (NSInteger)self) {
		if ([[userInfo objectForKey:@"domain"] isEqualToString:_domain]) {
			[self refreshDefaults];
		}
	}
}

- (void)dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[_defaults release];
	self.domain = nil;
	[_defaultsLock release];
	[super dealloc];
}

@end


