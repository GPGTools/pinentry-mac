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
static NSMutableDictionary *_sharedInstances = nil;

+ (id)gpgDefaults {
	return [self defaultsWithDomain:gpgDefaultsDomain];
}
+ (id)standardDefaults {
	return [self defaultsWithDomain:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
}
+ (id)defaultsWithDomain:(NSString *)domain  {
	if (!_sharedInstances) {
		_sharedInstances = [[NSMutableDictionary alloc] initWithCapacity:2];
	}
	GPGDefaults *defaultsController = [_sharedInstances objectForKey:domain];
	if (!defaultsController) {
		defaultsController = [[self alloc] initWithDomain:domain];
		[_sharedInstances setObject:defaultsController forKey:domain];
	}
	return defaultsController;
}
- (id)initWithDomain:(NSString *)domain {
	if ([self init]) {
		self.domain = domain;
	}
	return self;
}
- (id)init {
	if (self = [super init]) {
		_defaults = nil;
		_defaultDictionarys = nil;
		_defaultsLock = [[NSLock alloc] init];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsDidUpdated:) name:GPGDefaultsUpdatedNotification object:nil];
	}
	return self;
}

- (void)setDomain:(NSString *)value {
	if (value != _domain) {
		_domain = value;
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
	if (!obj && _defaultDictionarys) {
		for	(NSDictionary *dictionary in _defaultDictionarys) {
			obj = [dictionary objectForKey:defaultName];
			if (obj) {
				break;
			}
		}
	}
	[_defaultsLock unlock];
	return obj;
}
- (void)removeObjectForKey:(NSString *)defaultName {
	[_defaultsLock lock];
	[self.defaults removeObjectForKey:defaultName];
	[_defaultsLock unlock];
	[self writeToDisk];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName {
	[self setObject:[NSNumber numberWithInteger:value] forKey:defaultName];
}
- (NSInteger)integerForKey:(NSString *)defaultName {
	return [[self objectForKey:defaultName] integerValue];
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName {
	[self setObject:[NSNumber numberWithBool:value] forKey:defaultName];
}
- (BOOL)boolForKey:(NSString *)defaultName {
	return [[self objectForKey:defaultName] boolValue];
}

- (void)setFloat:(float)value forKey:(NSString *)defaultName {
	[self setObject:[NSNumber numberWithFloat:value] forKey:defaultName];
}
- (float)floatForKey:(NSString *)defaultName {
	return [[self objectForKey:defaultName] floatValue];
}

- (NSString *)stringForKey:(NSString *)defaultName {
	NSString *obj = [self objectForKey:defaultName];
	if (obj && [obj isKindOfClass:[NSString class]]) {
		return obj;
	}
	return nil;
}

- (NSArray *)arrayForKey:(NSString *)defaultName {
	NSArray *obj = [self objectForKey:defaultName];
	if (obj && [obj isKindOfClass:[NSArray class]]) {
		return obj;
	}
	return nil;	
}

- (NSDictionary *)dictionaryRepresentation {
	[_defaultsLock lock];
	NSDictionary *retDict = [self.defaults copy];
	[_defaultsLock unlock];
	return retDict;
}

- (void)registerDefaults:(NSDictionary *)dictionary {
	if (!_defaultDictionarys) {
		_defaultDictionarys = [[NSSet alloc] initWithObjects:dictionary, nil];
	} else {
		_defaultDictionarys = [_defaultDictionarys setByAddingObject:dictionary];
	}
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
	if (dictionary) {
		_defaults = [dictionary mutableCopy];
	} else {
		_defaults = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
}

- (NSMutableDictionary *)defaults {
	if (!_defaults) {
		[self refreshDefaults];
	}
	return _defaults;
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
	self.domain = nil;
}

@end








