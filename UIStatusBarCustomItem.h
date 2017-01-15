#import "common.h"

@interface UIStatusBarCustomItem : UIStatusBarItem

- (UIStatusBarItemView*)viewForManager:(id)manager;
- (void)setView:(UIStatusBarItemView*)view forManager:(id)manager;
- (void)removeAllViews;

- (void)setIndicatorName:(NSString*)name;

@property (nonatomic, retain) NSDictionary *properties;
@end
