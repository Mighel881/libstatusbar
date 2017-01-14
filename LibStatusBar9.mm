#import "common.h"
#import "LSStatusBarItem.h"

/*
This is simply a dummy class that can be used to check for the existence of libstatusbar8.
Protean, for one, uses it.
*/

NSMutableArray *registeredExtensions = [NSMutableArray array];

@interface LibStatusBar9 : NSObject
+ (BOOL)supported;
+ (void)addExtension:(NSString*)name identifier:(NSString*)identifier version:(NSString*)version;
+ (NSArray*)getCurrentExtensions;
+ (NSString*)getCurrentExtensionsString;
@end

@implementation LibStatusBar9
+ (BOOL)supported {
	// Currently "officially" supports:
	// iOS 7.0, 7.1
	//     8.0, 8.1
	// haha now it shall support 10.x
	return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") && SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"10.2");
}

+ (void)addExtension:(NSString*)name identifier:(NSString*)identifier version:(NSString*)version {
	if (!name || !identifier || !version) {
		return;
	}
	[registeredExtensions addObject:@{
		@"name": name,
		@"identifier": identifier,
		@"version": version
	}];
}

+ (NSArray*)getCurrentExtensions {
	return registeredExtensions;
}

+ (NSString*) getCurrentExtensionsString {
	NSString *ret = @"";
	for (NSDictionary *dict in registeredExtensions) {
		ret = [NSString stringWithFormat:@"%@ \n%@ (%@) %@",ret,dict[@"name"],dict[@"identifier"],dict[@"version"]];
	}
	return ret;
}
@end
