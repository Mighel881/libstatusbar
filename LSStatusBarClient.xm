#import "LSStatusBarClient.h"
#import "LSStatusBarServer.h"
#import "UIStatusBarCustomItem.h"
#import "LSStatusBarItem.h"
#import "common.h"

@interface UIStatusBarItem (libstatusbar)
+ (id)itemWithType:(NSInteger)type;
@end

@interface SBBulletinListController
- (SBBulletinListView*)listView;
@end

@interface SBNotificationCenterController
+ (instancetype)sharedInstanceIfExists;
@property(readonly, assign, nonatomic) SBNotificationCenterViewController* viewController;
@end

void UpdateStatusBar(CFNotificationCenterRef center, LSStatusBarClient* client) {
	[client updateStatusBar];
}

void ResubmitContent(CFNotificationCenterRef center, LSStatusBarClient* client) {
	[client resubmitContent];
	[client updateStatusBar];
}

extern "C" kern_return_t
bootstrap_look_up(mach_port_t bp, const char* service_name, mach_port_t *sp);
extern "C" mach_port_t bootstrap_port;

@implementation LSStatusBarClient
+ (instancetype)sharedInstance {
	static LSStatusBarClient* client;

	if (!client) {
		client = [[LSStatusBarClient alloc] init];
	}
	return client;
}

- (id)init {
	self = [super init];
	if (self) {
		_isLocal = %c(SpringBoard) ? YES : NO;

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
		HBLogDebug(@"[libstatusbar] invalid process, cancelling request to retrieve current message");
	}

	_currentMessage = nil;
	if (_isLocal) {
		_currentMessage = [LSStatusBarServer.sharedInstance currentMessage];
	} else {
		CPDistributedMessagingCenter* dmc = nil;

		if (!dmc && %c(CPDistributedMessagingCenter) != nil) {
			dmc = [CPDistributedMessagingCenter centerNamed:@"com.apple.springboard.libstatusbar"];
			rocketbootstrap_distributedmessagingcenter_apply(dmc);
		}

		if (dmc) {
			_currentMessage = [dmc sendMessageAndReceiveReplyName:@"currentMessage" userInfo:nil];
		}
	}
}

- (NSString*)titleStringAtIndex:(NSInteger)idx {
	if (idx < _titleStrings.count && idx >= 0) {
		return [_titleStrings objectAtIndex:idx];
	}
	return nil;
}

- (BOOL)processCurrentMessage {
	if (!_currentMessage) {
		return NO;
	}

	NSMutableArray* processedKeys = [[_currentMessage objectForKey:@"keys"] mutableCopy];

	_titleStrings = [_currentMessage objectForKey:@"titleStrings"];

	NSInteger keyidx = 64; //(cfvers >= CF_70) ? 32 : 24;

	extern NSMutableArray* customItems[3];

	for (int i=0; i<3; i++) {
		if (customItems[i]) {
			NSInteger cnt = [customItems[i] count]-1;
			for (; cnt>= 0; cnt--) {
				UIStatusBarCustomItem* item = [customItems[i] objectAtIndex:cnt];
				//UIStatusBarCustomItem* item = [allCustomItems objectAtIndex: cnt];

				NSString* indicatorName = [item indicatorName];

				NSObject* properties = nil;
				if (_currentMessage) {
					properties = [_currentMessage objectForKey:indicatorName];
				}

				if (!properties) {
					[item removeAllViews];
					[customItems[i] removeObjectAtIndex:cnt];
				} else {
					[processedKeys removeObject:indicatorName];

					NSInteger &type(MSHookIvar<NSInteger>(item, "_type"));
					if (type > keyidx) {
						keyidx = type;
					}
					item.properties = [properties isKindOfClass:[NSDictionary class]] ? (NSDictionary*) properties : nil;
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
			if ([%c(UIStatusBarItem) respondsToSelector:@selector(itemWithType:idiom:)]) {
				item = [%c(UIStatusBarItem) itemWithType:keyidx++ idiom:0];
			} else {
				item = [%c(UIStatusBarItem) itemWithType:keyidx++];
			}
			[item setIndicatorName:key];

			NSObject* properties = [_currentMessage objectForKey:key];
			item.properties = [properties isKindOfClass:[NSDictionary class]] ? (NSDictionary*) properties : nil;

			if ([item leftOrder]) {
				if (!customItems[0]) {
					customItems[0] = [[NSMutableArray alloc] init];
				}
				[customItems[0] addObject:item];
			} else if([item rightOrder]) {
				if(!customItems[1]) {
					customItems[1] = [[NSMutableArray alloc] init];
				}
				[customItems[1] addObject:item];
			} else if(item) {
				if(!customItems[2]) {
					customItems[2] = [[NSMutableArray alloc] init];
				}
				[customItems[2] addObject:item];
			}
		}
	}
	return YES;
}

- (void)updateStatusBar {
	if(!%c(UIApplication)) {
		return;
	}
	HBLogDebug(@"Updating StatusBar");
	[self retrieveCurrentMessage];

	// need a decent guard band because we do call before UIApp exists
	if ([self processCurrentMessage]) {
		if (%c(UIApplication) && [%c(UIApplication) sharedApplication]) {
			UIStatusBar* sb = [[%c(UIApplication) sharedApplication] statusBar];

			if(!sb) {
				return;
			}

			UIStatusBarForegroundView* _foregroundView = MSHookIvar<UIStatusBarForegroundView*>(sb, "_foregroundView");
			if (_foregroundView) {
				[sb forceUpdateData:NO];

				if (_isLocal) {
					if (%c(SBBulletinListController)) {
						SBBulletinListView* listview = [[%c(SBBulletinListController) sharedInstance] listView];
						if (listview) {
							UIStatusBar* _statusBar = MSHookIvar<id>(listview, "_statusBar");
							[_statusBar forceUpdateData:NO];
						}
					}

					if (%c(SBNotificationCenterController)) {
						SBNotificationCenterViewController *vc = [[%c(SBNotificationCenterController) sharedInstanceIfExists] viewController];
						if (vc) {
							UIStatusBar* _statusBar = MSHookIvar<id>(vc, "_statusBar");

							if (_statusBar) {
								// forceUpdateData: animated: doesn't work if statusbar._inProcessProvider = 1
								// bypass and directly do it.

								void* &_currentRawData(MSHookIvar<void*>(_statusBar, "_currentRawData"));
								[_statusBar forceUpdateToData:&_currentRawData animated:NO];
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
			[_submittedMessages setObject:properties forKey:item];
		} else {
			[_submittedMessages removeObjectForKey:item];
		}

		NSString* bundleId = NSBundle.mainBundle.bundleIdentifier;
		if (_isLocal) {
			[LSStatusBarServer.sharedInstance setProperties:properties forItem:item bundle:bundleId pid:[NSNumber numberWithInt: 0]];
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

			if (%c(CPDistributedMessagingCenter)) {
				CPDistributedMessagingCenter* dmc = [CPDistributedMessagingCenter centerNamed:@"com.apple.springboard.libstatusbar"];
				rocketbootstrap_distributedmessagingcenter_apply(dmc);

				[dmc sendMessageName:@"setProperties:userInfo:" userInfo:dict];
			} else {
				HBLogDebug(@"[libstatusbar] CPDistributedMessagingCenter was not found when calling -[LSStatusBarClientsetProperties:forItem:].");
			}
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
}
@end
