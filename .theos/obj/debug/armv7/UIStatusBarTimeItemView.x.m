#line 1 "UIStatusBarTimeItemView.x"
#import "common.h"
#import "LSStatusBarClient.h"

@interface UIStatusBarTimeItemView : UIStatusBarItemView

@end


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class UIStatusBarTimeItemView; 
static BOOL (*_logos_orig$_ungrouped$UIStatusBarTimeItemView$updateForNewData$actions$)(_LOGOS_SELF_TYPE_NORMAL UIStatusBarTimeItemView* _LOGOS_SELF_CONST, SEL, id, NSInteger); static BOOL _logos_method$_ungrouped$UIStatusBarTimeItemView$updateForNewData$actions$(_LOGOS_SELF_TYPE_NORMAL UIStatusBarTimeItemView* _LOGOS_SELF_CONST, SEL, id, NSInteger); static _UILegibilityImageSet* (*_logos_orig$_ungrouped$UIStatusBarTimeItemView$contentsImage)(_LOGOS_SELF_TYPE_NORMAL UIStatusBarTimeItemView* _LOGOS_SELF_CONST, SEL); static _UILegibilityImageSet* _logos_method$_ungrouped$UIStatusBarTimeItemView$contentsImage(_LOGOS_SELF_TYPE_NORMAL UIStatusBarTimeItemView* _LOGOS_SELF_CONST, SEL); 

#line 8 "UIStatusBarTimeItemView.x"

static BOOL _logos_method$_ungrouped$UIStatusBarTimeItemView$updateForNewData$actions$(_LOGOS_SELF_TYPE_NORMAL UIStatusBarTimeItemView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, NSInteger arg2) {
	NSString *&_timeString(MSHookIvar<NSString*>(self, "_timeString"));
	NSString *oldString = [_timeString retain];

	NSInteger idx = [[LSStatusBarClient.sharedInstance currentMessage][@"TitleStringIndex"] intValue];

	
	_timeString = [[LSStatusBarClient.sharedInstance titleStringAtIndex:idx] retain];

	
	if (!_timeString) {
		return _logos_orig$_ungrouped$UIStatusBarTimeItemView$updateForNewData$actions$(self, _cmd, arg1, arg2);
	}

	
	BOOL isSame = [oldString isEqualToString:_timeString];
	[oldString release];
	return !isSame;
}

static _UILegibilityImageSet* _logos_method$_ungrouped$UIStatusBarTimeItemView$contentsImage(_LOGOS_SELF_TYPE_NORMAL UIStatusBarTimeItemView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
	NSString *&_timeString(MSHookIvar<NSString*>(self, "_timeString"));
	NSMutableString *timeString = [_timeString mutableCopy];

	CGFloat maxlen;

	CGSize screenSz = UIScreen.mainScreen.bounds.size;
	maxlen = screenSz.width * 0.6f;

	
	if ([timeString sizeWithAttributes:@{NSFontAttributeName:[self textFont]}].width > maxlen) {
		[timeString replaceCharactersInRange:(NSRange){[timeString length]-1, 1} withString:@"…"];
		while ([timeString length]>3 && [timeString sizeWithAttributes:@{NSFontAttributeName:[self textFont]}].width > maxlen) {
			[timeString replaceCharactersInRange:(NSRange){[timeString length]-2, 1} withString:@""];
		}
	}

	NSString *oldTimeString = _timeString;
	_timeString = [timeString retain];

	id ret = _logos_orig$_ungrouped$UIStatusBarTimeItemView$contentsImage(self, _cmd);

	_timeString = oldTimeString;
	[timeString release];

	return ret;
}

static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$UIStatusBarTimeItemView = objc_getClass("UIStatusBarTimeItemView"); if (_logos_class$_ungrouped$UIStatusBarTimeItemView) {MSHookMessageEx(_logos_class$_ungrouped$UIStatusBarTimeItemView, @selector(updateForNewData:actions:), (IMP)&_logos_method$_ungrouped$UIStatusBarTimeItemView$updateForNewData$actions$, (IMP*)&_logos_orig$_ungrouped$UIStatusBarTimeItemView$updateForNewData$actions$);} else {HBLogError(@"logos: nil class %s", "UIStatusBarTimeItemView");}if (_logos_class$_ungrouped$UIStatusBarTimeItemView) {MSHookMessageEx(_logos_class$_ungrouped$UIStatusBarTimeItemView, @selector(contentsImage), (IMP)&_logos_method$_ungrouped$UIStatusBarTimeItemView$contentsImage, (IMP*)&_logos_orig$_ungrouped$UIStatusBarTimeItemView$contentsImage);} else {HBLogError(@"logos: nil class %s", "UIStatusBarTimeItemView");}} }
#line 57 "UIStatusBarTimeItemView.x"
