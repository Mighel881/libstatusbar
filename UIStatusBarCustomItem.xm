#import "common.h"
#import "UIStatusBarCustomItem.h"
#import "LSStatusBarItem.h"

//%subclass UIStatusBarCustomItem : UIStatusBarItem
%hook UIStatusBarCustomItem
- (NSInteger)type {
	return MSHookIvar<NSInteger>(self, "_type");
}

- (NSInteger)leftOrder {
	if (NSDictionary* properties = [self properties]) {
		NSNumber* nsalign = [properties objectForKey:@"alignment"];
		StatusBarAlignment alignment = nsalign ? (StatusBarAlignment) [nsalign intValue] : StatusBarAlignmentRight;
		if (alignment & StatusBarAlignmentLeft) {
			return 15;
		}
	}
	return 0;
}

- (NSInteger)rightOrder {
	if (NSDictionary* properties = [self properties]) {
		NSNumber* nsalign = [properties objectForKey:@"alignment"];
		StatusBarAlignment alignment = nsalign ? (StatusBarAlignment) [nsalign intValue] : StatusBarAlignmentRight;
		if (alignment & StatusBarAlignmentRight) {
			return 15;
		} else {
			return 0;
		}
	} else {
		return 15;
	}
}

- (NSInteger)priority {
	return %orig;
	//return 0;
}

%new
- (NSDictionary*)properties {
	return MSHookIvar<NSDictionary*>(self, "_properties");
}

%new
- (void)setProperties:(NSDictionary*)properties {
	__strong NSDictionary* &_properties(MSHookIvar<NSDictionary*>(self, "_properties"));
	_properties = properties;
}

- (Class)viewClass {
	NSString* customViewClass = [[self properties] objectForKey:@"customViewClass"];

	if (customViewClass) {
		Class ret = NSClassFromString(customViewClass);
		if (ret) {
			return ret;
		}
	}

	return %c(UIStatusBarCustomItemView);
}

- (NSString*)description {
	return [NSString stringWithFormat:@"UIStatusBarCustomItem [%@]", self.indicatorName];
}

- (NSString*)indicatorName {
	if (NSDictionary* properties = [self properties]) {
		NSString* name = [properties objectForKey:@"imageName"];
		if (name) {
			return name;
		}
	}
	return MSHookIvar<NSString*>(self, "_indicatorName");
}

%new
- (void)setIndicatorName:(NSString*) name {
	__strong NSString *&_indicatorName = MSHookIvar<NSString*>(self, "_indicatorName");
	_indicatorName = name;
}

%new
- (UIStatusBarItemView*)viewForManager:(UIStatusBarLayoutManager*)manager {
	CFMutableDictionaryRef &_views = MSHookIvar<CFMutableDictionaryRef>(self, "_views");
	if (_views) {
		return (UIStatusBarItemView*)CFDictionaryGetValue(_views, (void*) manager);
	} else {
		return nil;
	}
}

%new
- (void)setView:(UIStatusBarItemView*)view forManager:(UIStatusBarLayoutManager*)manager {
	CFMutableDictionaryRef &_views = MSHookIvar<CFMutableDictionaryRef>(self, "_views");
	if (!_views) {
		_views = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	}
	CFDictionarySetValue(_views, (void*) manager, (const void *)view);
}

void UIStatusBarCustomItem$removeFromSuperview(id key, UIView* view) {
	if (view) {
		[view removeFromSuperview];
	}
}

%new
- (void)removeAllViews {
	CFMutableDictionaryRef &_views = MSHookIvar<CFMutableDictionaryRef>(self, "_views");

	if (_views) {
		CFDictionaryApplyFunction(_views, (CFDictionaryApplierFunction) UIStatusBarCustomItem$removeFromSuperview, NULL);
	}
}
%end

%ctor {
	// We need this because using %subclass doesn't seem to let us then use class_addIvar to add the necessary ivars...
	// no matter, this isn't that bad. Just initialize the hook *after* creating the class.
	Class cls = objc_allocateClassPair(%c(UIStatusBarItem), "UIStatusBarCustomItem", 0);

	class_addIvar(cls, "_views", sizeof(id), 0x4, "@");

	class_addIvar(cls, "_properties", sizeof(id), 0x4, "@");
	class_addIvar(cls, "_indicatorName", sizeof(id), 0x4, "@");

	objc_registerClassPair(cls);

	%init;
}
