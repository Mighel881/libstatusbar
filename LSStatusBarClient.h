@interface LSStatusBarClient : NSObject {
	BOOL _isLocal;
	NSDictionary *_currentMessage;
	NSMutableDictionary *_submittedMessages;

	NSArray *_titleStrings;
}

+ (instancetype)sharedInstance;

- (instancetype)init;

- (NSDictionary*)currentMessage;
- (void)retrieveCurrentMessage;
- (BOOL)processCurrentMessage;
- (void)resubmitContent;
- (void)updateStatusBar;

- (void)setProperties:(id)properties forItem:(NSString*)item;

- (NSString*)titleStringAtIndex:(int)index;

@end
