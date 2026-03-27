#import <UIKit/UIKit.h>

@class WIFIRule;

NS_ASSUME_NONNULL_BEGIN

@protocol WiFiRuleCellDelegate <NSObject>
- (void)ruleCellDidToggleEnabled:(UITableViewCell *)cell;
- (void)ruleCellDidTapEdit:(UITableViewCell *)cell;
- (void)ruleCellDidTapDelete:(UITableViewCell *)cell;
@end

@interface WiFiRuleCell : UITableViewCell

@property (nonatomic, weak, nullable) id<WiFiRuleCellDelegate> delegate;
@property (nonatomic, strong, readonly) UISwitch *enabledSwitch;
@property (nonatomic, strong, readonly) UILabel *wifiNameLabel;
@property (nonatomic, strong, readonly) UILabel *shortcutNameLabel;
@property (nonatomic, strong, readonly) UILabel *scheduleLabel;
@property (nonatomic, strong, readonly) UIButton *editButton;
@property (nonatomic, strong, readonly) UIButton *deleteButton;

- (void)configureWithRule:(WIFIRule *)rule;

@end

NS_ASSUME_NONNULL_END
