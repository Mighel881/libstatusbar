#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <syslog.h>
#import <mach/mach.h>
#include <sys/event.h>
#include <execinfo.h>
#include <sys/time.h>
#import <dlfcn.h>
#import <objc/message.h>
#import <substrate.h>
#import <notify.h>
#import <unistd.h>
#import <objc/runtime.h>

#import "CPDistributedMessagingCenter.h"
#import "UIApplication_libstatusbar.h"
#import "headers.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

//extern "C" int SBSSpringBoardServerPort();

enum sandbox_filter_type {
	SANDBOX_FILTER_NONE = 0,
	SANDBOX_FILTER_PATH = 1,
	SANDBOX_FILTER_GLOBAL_NAME = 2,
	SANDBOX_FILTER_LOCAL_NAME = 3,
	SANDBOX_CHECK_NO_REPORT = 0x40000000
};

extern "C" int sandbox_check(pid_t pid, const char *operation, enum sandbox_filter_type type, ...);