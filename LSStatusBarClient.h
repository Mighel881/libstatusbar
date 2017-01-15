@interface LSStatusBarClient : NSObject {
	bool _isLocal;
	NSDictionary *_currentMessage;
	NSMutableDictionary *_submittedMessages;

	NSArray *_titleStrings;
}

+ (instancetype)sharedInstance;

- (id)init;

- (NSDictionary*)currentMessage;
- (void)retrieveCurrentMessage;
- (BOOL)processCurrentMessage;
- (void)resubmitContent;
- (void)updateStatusBar;

- (void)setProperties:(id)properties forItem:(NSString*)item;

- (NSString*)titleStringAtIndex:(NSInteger)idx;

@end
