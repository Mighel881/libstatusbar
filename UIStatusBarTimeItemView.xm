#import "common.h"
#import "LSStatusBarClient.h"

@interface UIStatusBarTimeItemView : UIStatusBarItemView
// Dummy interface for ARC
@end

%hook UIStatusBarTimeItemView
- (BOOL)updateForNewData:(id)arg1 actions:(NSInteger)arg2 {
	NSString *&_timeString(MSHookIvar<NSString*>(self, "_timeString"));
	NSString *oldString = [_timeString retain];

	NSInteger idx = [[LSStatusBarClient.sharedInstance currentMessage][@"TitleStringIndex"] intValue];

	// Fetch current string
	_timeString = [[LSStatusBarClient.sharedInstance titleStringAtIndex:idx] retain];

	// If not...
	if (!_timeString) {
		return %orig;
	}

	// Did it change?
	BOOL isSame = [oldString isEqualToString:_timeString];
	[oldString release];
	return !isSame;
}

- (_UILegibilityImageSet*)contentsImage {
	NSString *&_timeString(MSHookIvar<NSString*>(self, "_timeString"));
	NSMutableString *timeString = [_timeString mutableCopy];

	CGFloat maxlen;

	CGSize screenSz = UIScreen.mainScreen.bounds.size;
	maxlen = screenSz.width * 0.6f;

	// ellipsize strings if they're too long
	if ([timeString sizeWithAttributes:@{NSFontAttributeName:[self textFont]}].width > maxlen) {
		[timeString replaceCharactersInRange:(NSRange){[timeString length]-1, 1} withString:@"…"];
		while ([timeString length]>3 && [timeString sizeWithAttributes:@{NSFontAttributeName:[self textFont]}].width > maxlen) {
			[timeString replaceCharactersInRange:(NSRange){[timeString length]-2, 1} withString:@""];
		}
	}

	NSString *oldTimeString = _timeString;
	_timeString = [timeString retain];

	id ret = %orig;

	_timeString = oldTimeString;
	[timeString release];

	return ret;
}
%end
