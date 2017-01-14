#import <objc/runtime.h>
#import "common.h"
#import "LSStatusBarServer.h"
#import "LSStatusBarItem.h"

NSUInteger TitleStringIndex = -1;

void updateLockStatus(CFNotificationCenterRef center, LSStatusBarServer* server) {
	[server updateLockStatus];
}

void incrementTimer() {
	[[LSStatusBarServer sharedInstance] incrementTimer];
}

@implementation LSStatusBarServer
+ (instancetype)sharedInstance {
	static LSStatusBarServer* server;

	if (!server) {
		server = [[self alloc] init];
	}
	return server;
}

- (id)init {
	self = [super init];
	if (self) {
		_dmc = [CPDistributedMessagingCenter centerNamed:@"com.apple.springboard.libstatusbar"];

		if (_dmc) {
			rocketbootstrap_distributedmessagingcenter_apply(_dmc);

			[_dmc runServerOnCurrentThread];
			[_dmc registerForMessageName:@"currentMessage" target:self selector:@selector(currentMessage)];
			[_dmc registerForMessageName:@"setProperties:userInfo:" target:self selector:@selector(setProperties:userInfo:)];
			HBLogDebug(@"[libstatusbar] server running in process without AppSupport/CPDistributedMessagingCenter");
		}
		_currentMessage = [[NSMutableDictionary alloc] init];
		_currentKeys = [[NSMutableArray alloc] init];
		_currentKeyUsage = [[NSMutableDictionary alloc] init];

		CFNotificationCenterRef darwin = CFNotificationCenterGetDarwinNotifyCenter();
		CFNotificationCenterAddObserver(darwin, (const void *)self, (CFNotificationCallback) updateLockStatus, CFSTR("com.apple.springboard.lockstate"), (const void *)self, CFNotificationSuspensionBehaviorDeliverImmediately);

		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("LSBDidLaunchNotification"), nil, nil, YES);
	}
	return self;
}

- (NSMutableDictionary*)currentMessage {
	return [_currentMessage copy]; // copy to attempt crash fix of enumeration
}

- (void)postChanged {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("libstatusbar_changed"), nil, nil, YES);
}

- (void)enqueuePostChanged {
	NSRunLoop* loop = [NSRunLoop mainRunLoop];

	[loop cancelPerformSelector:@selector(postChanged) target:self argument:nil];
	[loop performSelector:@selector(postChanged) target:self argument:nil order:0 modes:@[NSDefaultRunLoopMode]];
}

- (void)processMessageCommonWithFocus:(NSString*)item {
	timeHidden = NO;

	NSMutableArray* titleStrings = [NSMutableArray array];
	for (NSString* key in [_currentKeys copy]) {
		NSDictionary* dict = [_currentMessage objectForKey:key];

		if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
			continue;
		}
		NSNumber* alignment = [dict objectForKey:@"alignment"];
		if (alignment && ((StatusBarAlignment) [alignment intValue]) == StatusBarAlignmentCenter) {
			NSNumber* visible = [dict objectForKey:@"visible"];
			if (!visible || [visible boolValue]) {
				NSString* titleString = [dict objectForKey:@"titleString"];
				if (titleString && [titleString length]) {
					if (item && [item isEqualToString: key]) {
						[self setState:[titleStrings count]];
						[self resyncTimer];
					}
					[titleStrings addObject:titleString];

					if ([[dict objectForKey: @"hidesTime"] boolValue]) {
						timeHidden = YES;
					}
				}
			}
		}
	}

	[_currentMessage setValue:_currentKeys forKey:@"keys"];
	if ([titleStrings count]) {
		[_currentMessage setValue:titleStrings forKey:@"titleStrings"];
		[self startTimer];
	} else {
		[_currentMessage setValue:nil forKey:@"titleStrings"];
		[self stopTimer];
	}

	[self enqueuePostChanged];
}

static void NoteExitKQueueCallback(
    CFFileDescriptorRef f,
    CFOptionFlags       callBackTypes,
    NSNumber *              pidinfo
) {
	  [LSStatusBarServer.sharedInstance pidDidExit:[pidinfo autorelease]];
}


void MonitorPID(NSNumber* pid) {
    //FILE *                f;
    NSInteger                     kq;
    struct kevent           changes;
		CFFileDescriptorContext context = { 0, [pid retain], NULL, NULL, NULL };
    CFRunLoopSourceRef      rls;

    kq = kqueue();

    EV_SET(&changes, [pid intValue], EVFILT_PROC, EV_ADD | EV_RECEIPT, NOTE_EXIT, 0, NULL);
    (void) kevent(kq, &changes, 1, &changes, 1, NULL);

    CFFileDescriptorRef noteExitKQueueRef = CFFileDescriptorCreate(NULL, kq, true, (CFFileDescriptorCallBack) NoteExitKQueueCallback, &context);
    rls = CFFileDescriptorCreateRunLoopSource(NULL, noteExitKQueueRef, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRelease(rls);

    CFFileDescriptorEnableCallBacks(noteExitKQueueRef, kCFFileDescriptorReadCallBack);

}

- (void)registerPid:(NSNumber*)thepid {
	NSInteger pid = [thepid intValue];
	if (!pid) {
		return;
	}

	if (!clientPids) {
		clientPids = [[NSMutableArray alloc] init];
	}
	if (![clientPids containsObject:thepid]) {
		[clientPids addObject:thepid];
		MonitorPID(thepid);
	}
}

- (void)setProperties:(id)properties forItem:(NSString*)item bundle:(NSString*)bundle pid:(NSNumber*)pid {
	if (!item || !pid) {
		HBLogDebug(@"[libstatusbar] Server: Missing info, returning... %@ %@", [item description], [pid description]);
		return;
	}

	[self registerPid:pid];

	// get the current item usage by bundles

	NSMutableArray* pids = [_currentKeyUsage objectForKey:item];
	if (!pids) {
		pids = [NSMutableArray array];
		[_currentKeyUsage setObject:pids forKey:item];
	}

	NSUInteger itemIdx = [_currentKeys indexOfObject:item];


	if (properties) {
		[_currentMessage setValue:properties forKey:item];

		if (![pids containsObject:pid]) {
			[pids addObject:pid];
		}

		if (itemIdx == NSNotFound) {
			[_currentKeys addObject:item];
		}
	} else {
		[pids removeObject:pid];

		if ([pids count]==0) {
			// object is truly dead
			[_currentMessage setValue:nil forKey:item];

			if (itemIdx!=NSNotFound) {
				[_currentKeys removeObjectAtIndex:itemIdx];
			}
		}
	}

	// find all title strings
	[self processMessageCommonWithFocus:item];
}

- (void)pidDidExit:(NSNumber*)pid {
	NSInteger nKeys = [_currentKeys count];
	for (int i=nKeys - 1; i>=0; i--) {
		NSString* item = [_currentKeys objectAtIndex:i];

		NSMutableArray* pids = [_currentKeyUsage objectForKey:item];
		if (!pids) {
			continue;
		}

		if ([pids containsObject:pid]) {
			[pids removeObject:pid];
			HBLogDebug(@"[libstatusbar] Server: Removing object for PID %@", pid);

			if ([pids count]==0) {
				// object is truly dead
				[_currentMessage setValue:nil forKey:item];

				NSUInteger itemIdx = [_currentKeys indexOfObject:item];
				if (itemIdx!=NSNotFound) {
					[_currentKeys removeObjectAtIndex:itemIdx];
				}
			}
		}
	}

	[self processMessageCommonWithFocus:nil];
}

- (void)appDidExit:(NSString*)bundle {
	NSInteger nKeys = [_currentKeys count];
	for (int i=nKeys - 1; i>=0; i--) {
		NSString* item = [_currentKeys objectAtIndex: i];

		NSMutableArray* pids = [_currentKeyUsage objectForKey:item];
		if (!pids) {
			continue;
		}

		if ([pids containsObject:bundle]) {
			[pids removeObject:bundle];
			HBLogDebug(@"[libstatusbar] Server: Removing object for bundle %@", bundle);

			if ([pids count]==0) {
				// object is truly dead
				[_currentMessage setValue:nil forKey:item];

				NSUInteger itemIdx = [_currentKeys indexOfObject:item];
				if (itemIdx != NSNotFound) {
					[_currentKeys removeObjectAtIndex:itemIdx];
				}
			}
		}
	}

	[self processMessageCommonWithFocus: nil];
}

- (void)setProperties:(NSString*)message userInfo:(NSDictionary*)userInfo {
	NSString* item = [userInfo objectForKey:@"item"];
	NSDictionary* properties = [userInfo objectForKey:@"properties"];
	NSString* bundleId = [userInfo objectForKey:@"bundle"];
	NSNumber* pid = [userInfo objectForKey:@"pid"];

	[self setProperties:properties forItem:item bundle:bundleId pid:pid];
}

- (void)setState:(NSUInteger)newState {
	_currentMessage[@"TitleStringIndex"] = @(newState);
	[self enqueuePostChanged];
}

- (void)resyncTimer {
	if (timer) {
		CFRunLoopTimerInvalidate(timer);
		CFRelease(timer);

		timer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+3.5f, 3.5f, 0, 0, (CFRunLoopTimerCallBack) incrementTimer, NULL);
		CFRunLoopAddTimer(CFRunLoopGetMain(), timer, kCFRunLoopCommonModes);
	}
}

- (void)startTimer {
	// is timer already running?
	if (timer) {
		HBLogDebug(@"[libstatusbar] Server: Timer is already active. Ignoring request to start timer.");
		return;
	}

	// check lock status
	uint64_t locked; {
		static int token = -1;
		if (token < 0) {
			notify_register_check("com.apple.springboard.lockstate", &token);
		}
		notify_get_state(token, &locked);
	}

	// reset timer state
	[self stopTimer];

	if (!locked) {
		NSArray* titleStrings = [_currentMessage objectForKey: @"titleStrings"];
		if (titleStrings && [titleStrings count]) {
			timer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+3.5f, 3.5f, 0, 0, (CFRunLoopTimerCallBack) incrementTimer, NULL);
			CFRunLoopAddTimer(CFRunLoopGetMain(), timer, kCFRunLoopCommonModes);

			{
				[self setState: 0];

				[self enqueuePostChanged];
			}

		}
	}
}

- (void)stopTimer {
	// reset the statusbar state
	if (timer) {
		[self enqueuePostChanged];
	}// only post a notification if the timer was running
	[self setState:NSNotFound];
	// kill timer
	if (timer) {
		CFRunLoopTimerInvalidate(timer);
		CFRelease(timer);
		timer = nil;
		TitleStringIndex = -1;
		[self enqueuePostChanged];
	}
}

- (void)incrementTimer {
	NSArray* titleStrings = [_currentMessage objectForKey:@"titleStrings"];

	if (titleStrings && [titleStrings count]) {
		NSInteger value = TitleStringIndex; // -1 ++ = 0. so it should work
		TitleStringIndex++;
		if (timeHidden ? (value >= [titleStrings count]) : (value > [titleStrings count]) ) {
			value = 0;
			TitleStringIndex = -1;
		}
		[self setState:value];
	} else {
		[self stopTimer];
	}
}

- (void)updateLockStatus {
	[self stopTimer];
	[self startTimer];
}
@end
