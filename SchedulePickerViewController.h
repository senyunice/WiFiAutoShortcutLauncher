#import <UIKit/UIKit.h>

@class SchedulePickerViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol SchedulePickerDelegate <NSObject>
- (void)schedulePicker:(SchedulePickerViewController *)picker didSelectSchedule:(NSInteger)scheduleType;
@end

@interface SchedulePickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign, nullable) id<SchedulePickerDelegate> delegate;
@property (nonatomic, assign) NSInteger selectedSchedule;

@end

NS_ASSUME_NONNULL_END
