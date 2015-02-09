#import "common.h"
#import "UIStatusBarCustomItemView.h"

@interface UIColor (ss)
- (NSString*) styleString;
@end

@interface UIImage (fiwc)
- (UIImage*) _flatImageWithColor: (UIColor*) color;
@end

@interface UIStatusBarItemView (lss)
- (int) legibilityStyle;
- (float) legibilityStrength;
@end

@interface UIStatusBarCustomItemView (fgs)
- (UIStatusBarForegroundStyle*) foregroundStyle;
-(UIStatusBarItem*) item;
@end

NSMutableDictionary* cachedImages[5];

%subclass UIStatusBarCustomItemView : UIStatusBarItemView
-(_UILegibilityImageSet*) contentsImage
{
	UIStatusBarForegroundStyle* fs = [self foregroundStyle];
	NSString* itemName = self.item.indicatorName;
	
	UIColor* tintColor = [fs tintColor];
	
	NSString* expandedName_default = [fs expandedNameForImageName: itemName];
	NSString* expandedName_cache = [NSString stringWithFormat: @"%@_%@.png", expandedName_default, [tintColor styleString]]; 

	if(!cachedImages[4])
	{
		cachedImages[4] = [[NSMutableDictionary alloc] init];
	}
	if(cachedImages[4])
	{
		id ret = [cachedImages[4] objectForKey: expandedName_cache];
		if(ret)
			return ret;
	}
	
	bool isBlack = [tintColor isEqual: [UIColor blackColor]];
	bool isLockscreen = [fs isKindOfClass: objc_getClass("UIStatusBarLockScreenForegroundStyleAttributes")];
	
	UIImage* image_color = [UIImage kitImageNamed: [NSString stringWithFormat: @"%@_%@_Color", isLockscreen?  @"LockScreen" : isBlack ? @"Black" : @"White", itemName]];
	if(!image_color)
	{
		NSBundle* kitbundle = [NSBundle bundleWithPath: @"/System/Library/Frameworks/UIKit.framework"];
		image_color = [UIImage imageNamed: [NSString stringWithFormat: @"%@_%@_Color", isLockscreen?  @"LockScreen" : isBlack ? @"Black" : @"White", itemName] inBundle: kitbundle];
	}
	
	UIImage* image_base = 0;
	if(!image_color)
	{
		image_base = [UIImage kitImageNamed: expandedName_default];

		if(!image_base)
		{
			NSBundle* kitbundle = [NSBundle bundleWithPath: @"/System/Library/Frameworks/UIKit.framework"];
			image_base = [UIImage imageNamed: expandedName_default inBundle: kitbundle];
		}
	}
	
	UIImage* image = image_color;
	if(!image && image_base)
	{
		image = [image_base _flatImageWithColor: tintColor];
	}

	_UILegibilityImageSet* ret = [%c(_UILegibilityImageSet) imageFromImage: image withShadowImage: nil];//image_sh];
	
	if(ret && cachedImages[4])
	{
		[cachedImages[4] setObject: ret forKey: expandedName_cache];
	}

	return ret;
}
%end