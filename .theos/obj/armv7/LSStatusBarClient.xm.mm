#line 1 "LSStatusBarClient.xm"
#import "LSStatusBarClient.h"
#import "LSStatusBarServer.h"
#import "UIStatusBarCustomItem.h"
#import "LSStatusBarItem.h"
#import "common.h"

@interface UIStatusBarItem (libstatusbar)
+ (id)itemWithType:(int) type;
@end

@interface SBBulletinListController
- (id)listView;
@end

@interface SBNotificationCenterController
+ (id)sharedInstanceIfExists;
@property(readonly, assign, nonatomic) UIViewController* viewController;
@end

void UpdateStatusBar(CFNotificationCenterRef center, LSStatusBarClient* client) {
	[client updateStatusBar];
}

void ResubmitContent(CFNotificationCenterRef center, LSStatusBarClient* client) {
	[client resubmitContent];
	[client updateStatusBar];
}

extern "C" kern_return_t bootstrap_look_up(mach_port_t bp, const char* service_name, mach_port_t *sp);
extern "C" mach_port_t bootstrap_port;


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

@class UIStatusBarItem; @class CPDistributedMessagingCenter; @class UIApplication; @class SpringBoard; @class SBNotificationCenterController; @class SBBulletinListController; 

static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$UIStatusBarItem(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("UIStatusBarItem"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBNotificationCenterController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBNotificationCenterController"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBBulletinListController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBBulletinListController"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SpringBoard(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SpringBoard"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$UIApplication(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("UIApplication"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$CPDistributedMessagingCenter(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("CPDistributedMessagingCenter"); } return _klass; }
#line 32 "LSStatusBarClient.xm"
@implementation LSStatusBarClient
+ (id)sharedInstance {
	static LSStatusBarClient* client;

	if (!client) {
		client = [[LSStatusBarClient alloc] init];
	}
	return client;
}

- (id)init {
	self = [super init];
	if (self) {
		_isLocal = _logos_static_class_lookup$SpringBoard() ? YES : NO;

		CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
		CFNotificationCenterAddObserver(darwin, (const void *)self, (CFNotificationCallback) UpdateStatusBar, CFSTR("libstatusbar_changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		CFNotificationCenterAddObserver(darwin, (const void *)self, (CFNotificationCallback) ResubmitContent, CFSTR("LSBDidLaunchNotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	}
	return self;
}

- (NSDictionary*)currentMessage {
	return _currentMessage;
}

- (void)retrieveCurrentMessage {
	NSString *executableName = NSBundle.mainBundle.executablePath;
	if ([executableName rangeOfString:@".appex"].location != NSNotFound) {
		NSLog(@"[libstatusbar] invalid process, cancelling request to retrieve current message");
	}

	[_currentMessage release];
	if (_isLocal) {
		_currentMessage = [[[LSStatusBarServer sharedInstance] currentMessage] retain];
	} else {
		CPDistributedMessagingCenter* dmc = nil;

		if (!dmc && _logos_static_class_lookup$CPDistributedMessagingCenter() != nil) {
			dmc = [_logos_static_class_lookup$CPDistributedMessagingCenter() centerNamed:@"com.apple.springboard.libstatusbar"];

			void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*) = NULL;
			if (!rocketbootstrap_distributedmessagingcenter_apply) {
				void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
				if (handle) {
					rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
					dlclose(handle);
				}
			}
			if (rocketbootstrap_distributedmessagingcenter_apply) {
				rocketbootstrap_distributedmessagingcenter_apply(dmc);
			}
		}

		if (dmc) {
			_currentMessage = [[dmc sendMessageAndReceiveReplyName: @"currentMessage" userInfo: nil] retain];
		}
	}
}

- (NSString*)titleStringAtIndex:(int)idx {
	if (idx < _titleStrings.count && idx >= 0) {
		return [_titleStrings objectAtIndex:idx];
	}
	return nil;
}

- (bool)processCurrentMessage {
	if (!_currentMessage) {
		return NO;
	}

	NSMutableArray* processedKeys = [[_currentMessage objectForKey:@"keys"] mutableCopy];

	[_titleStrings release];
	_titleStrings = [[_currentMessage objectForKey: @"titleStrings"] retain];

	int keyidx = 64; 

	extern NSMutableArray* customItems[3];

	for (int i=0; i<3; i++) {
		if (customItems[i]) {
			int cnt = [customItems[i] count]-1;
			for (; cnt>= 0; cnt--) {
				UIStatusBarCustomItem* item = [customItems[i] objectAtIndex: cnt];
				

				NSString* indicatorName = [item indicatorName];

				NSObject* properties = nil;
				if (_currentMessage) {
					properties = [_currentMessage objectForKey: indicatorName];
				}

				if (!properties) {
					[item removeAllViews];
					[customItems[i] removeObjectAtIndex:cnt];
				} else {
					[processedKeys removeObject: indicatorName];

					int &type(MSHookIvar<int>(item, "_type"));
					if (type > keyidx) {
						keyidx = type;
					}
					item.properties = [properties isKindOfClass: [NSDictionary class]] ? (NSDictionary*) properties : nil;
				}
			}
		} else {
			customItems[i] = [[NSMutableArray alloc] init];
		}
	}

	keyidx++;

	if (processedKeys && [processedKeys count]) {
		for (NSString* key in processedKeys) {
			UIStatusBarCustomItem* item = nil;
			if ([_logos_static_class_lookup$UIStatusBarItem() respondsToSelector:@selector(itemWithType:idiom:)]) {
				item = [_logos_static_class_lookup$UIStatusBarItem() itemWithType:keyidx++ idiom:0];
			} else {
				item = [_logos_static_class_lookup$UIStatusBarItem() itemWithType:keyidx++];
			}
			[item setIndicatorName: key];

			NSObject* properties = [_currentMessage objectForKey:key];
			item.properties = [properties isKindOfClass: [NSDictionary class]] ? (NSDictionary*) properties : nil;

			if ([item leftOrder]) {
				if (!customItems[0]) {
					customItems[0] = [[NSMutableArray alloc] init];
				}
				[customItems[0] addObject: item];
			} else if([item rightOrder]) {
				if(!customItems[1]) {
					customItems[1] = [[NSMutableArray alloc] init];
				}
				[customItems[1] addObject: item];
			} else if(item) {
				if(!customItems[2]) {
					customItems[2] = [[NSMutableArray alloc] init];
				}
				[customItems[2] addObject: item];
			}
		}
	}

	[processedKeys release];
	return YES;
}

- (void)updateStatusBar {
	if(!_logos_static_class_lookup$UIApplication()) {
		return;
	}

	[self retrieveCurrentMessage];

	
	if ([self processCurrentMessage]) {
		if (_logos_static_class_lookup$UIApplication() && [_logos_static_class_lookup$UIApplication() sharedApplication]) {
			UIStatusBar* sb = [[_logos_static_class_lookup$UIApplication() sharedApplication] statusBar];

			if(!sb) {
				return;
			}

			UIStatusBarForegroundView* _foregroundView = MSHookIvar<UIStatusBarForegroundView*>(sb, "_foregroundView");
			if (_foregroundView) {
				[sb forceUpdateData: NO];

				if (_isLocal) {
					if (_logos_static_class_lookup$SBBulletinListController()) {
						id listview = [[_logos_static_class_lookup$SBBulletinListController() sharedInstance] listView];
						if(listview) {
							id _statusBar = MSHookIvar<id>(listview, "_statusBar");
							[_statusBar forceUpdateData: NO];
						}
					}

					if (_logos_static_class_lookup$SBNotificationCenterController()) {
						id vc = [[_logos_static_class_lookup$SBNotificationCenterController() sharedInstanceIfExists] viewController];
						if (vc) {
							id _statusBar = MSHookIvar<id>(vc, "_statusBar");

							if (_statusBar) {
								
								

								void* &_currentRawData(MSHookIvar<void*>(_statusBar, "_currentRawData"));
								[_statusBar forceUpdateToData: &_currentRawData animated: NO];
							}
						}
					}
				}
			}
		}
	}
}

- (void)setProperties:(id)properties forItem:(NSString*)item {
	if (item) {
		if (!_submittedMessages) {
			_submittedMessages = [[NSMutableDictionary alloc] init];
		}
		if (properties) {
			[_submittedMessages setObject: properties forKey: item];
		} else {
			[_submittedMessages removeObjectForKey: item];
		}

		NSString* bundleId = [[NSBundle mainBundle] bundleIdentifier];
		if (_isLocal) {
			[[LSStatusBarServer sharedInstance] setProperties:properties forItem:item bundle:bundleId pid:[NSNumber numberWithInt: 0]];
		} else {
			NSNumber* pid = [NSNumber numberWithInt:getpid()];

			NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithCapacity:4];
			if (item) {
				[dict setObject:item forKey:@"item"];
			}
			if (pid) {
				[dict setObject:pid forKey:@"pid"];
			}
			if (properties) {
				[dict setObject:properties forKey:@"properties"];
			}
			if (bundleId) {
				[dict setObject:bundleId forKey:@"bundle"];
			}

			if (_logos_static_class_lookup$CPDistributedMessagingCenter()) {
				CPDistributedMessagingCenter* dmc = [_logos_static_class_lookup$CPDistributedMessagingCenter() centerNamed:@"com.apple.springboard.libstatusbar"];

				void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*) = NULL;
				if (!rocketbootstrap_distributedmessagingcenter_apply) {
					void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
					if(handle) {
						rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
						dlclose(handle);
					}
				}
				if(rocketbootstrap_distributedmessagingcenter_apply) {
					rocketbootstrap_distributedmessagingcenter_apply(dmc);
				}

				[dmc sendMessageName:@"setProperties:userInfo:" userInfo:dict];
			} else {
				NSLog(@"[libstatusbar] CPDistributedMessagingCenter was not found when calling -[LSStatusBarClientsetProperties:forItem:].");
			}

			[dict release];
		}
	}
}

- (void)resubmitContent {
	NSDictionary* messages = _submittedMessages;
	if (!messages) {
		return;
	}
	_submittedMessages = nil;

	for (NSString* key in messages) {
		[self setProperties:[messages objectForKey:key] forItem:key];
	}

	[messages release];
}
@end
#line 302 "LSStatusBarClient.xm"
