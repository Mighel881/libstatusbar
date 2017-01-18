@interface LSStatusBarClient : NSObject {
	bool _isLocal;
	NSDictionary *_currentMessage;
	NSMutableDictionary *_submittedMessages;

	NSArray *_titleStrings;
}

+ (instancetype)sharedInstance;

- (instancetype)init;

- (NSDictionary*)currentMessage;
- (void)retrieveCurrentMessage;
- (bool)processCurrentMessage;
- (void)resubmitContent;
- (void)updateStatusBar;

- (void)setProperties:(id)properties forItem:(NSString*)item;

- (NSString*)titleStringAtIndex:(int)index;

@end
