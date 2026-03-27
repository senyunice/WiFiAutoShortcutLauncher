#import <UIKit/UIKit.h>

@class WIFIRule;

NS_ASSUME_NONNULL_BEGIN

@interface RootViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) UITableView *mainTableView;
@property (nonatomic, strong, readonly) NSMutableArray<WIFIRule *> *rules;
@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) BOOL weekdayModeEnabled;
@property (nonatomic, assign) BOOL weekendModeEnabled;
@property (nonatomic, copy) NSString *disabledStartTime;
@property (nonatomic, copy) NSString *disabledEndTime;

- (void)addRule;
- (void)editRule:(NSInteger)index;
- (void)deleteRule:(NSInteger)index;
- (void)reloadData;
- (NSString *)getPreferencePath;

@end

NS_ASSUME_NONNULL_END
