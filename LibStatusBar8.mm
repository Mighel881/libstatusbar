/*
This is simply a dummy class that can be used to check for the existence of libstatusbar. 
Protean, for one, uses it. 
*/

@interface LibStatusBar8 : NSObject
@end

@implementation LibStatusBar8
+(BOOL) supported { return YES; }
@end