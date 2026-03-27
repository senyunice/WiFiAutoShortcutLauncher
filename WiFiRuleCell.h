#import <UIKit/UIKit.h>

@class WIFIRule;

NS_ASSUME_NONNULL_BEGIN

@protocol WiFiRuleCellDelegate <NSObject>
- (void)ruleCellDidToggleEnabled:(UITableViewCell *)cell;
- (void)ruleCellDidTapEdit:(UITableViewCell *)cell;
- (void)ruleCellDidTapDelete:(UITableViewCell *)cell;
@end

@interface WiFiRuleCell : UITableViewCell

@property (nonatomic, assign, nullable) id<WiFiRuleCellDelegate> delegate;
@property (nonatomic, strong, readwrite) UISwitch *enabledSwitch;
@property (nonatomic, strong, readwrite) UILabel *wifiNameLabel;
@property (nonatomic, strong, readwrite) UILabel *shortcutNameLabel;
@property (nonatomic, strong, readwrite) UILabel *scheduleLabel;
@property (nonatomic, strong, readwrite) UIButton *editButton;
@property (nonatomic, strong, readwrite) UIButton *deleteButton;

- (void)configureWithRule:(WIFIRule *)rule;

@end

NS_ASSUME_NONNULL_END
