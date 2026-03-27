//
//  WiFiRuleCell.mm
//  WiFiAutoShortcutLauncher
//
//  WiFi自动快捷指令启动器 - 自定义规则单元格
//

#import "WiFiRuleCell.h"
#import "WIFIRule.h"

@implementation WiFiRuleCell

#pragma mark - Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contentView.backgroundColor = [UIColor systemBackgroundColor];

    // 主容器
    UIView *containerView = [[UIView alloc] init];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:containerView];

    // WiFi图标
    UIImageView *wifiIcon = [[UIImageView alloc] init];
    wifiIcon.translatesAutoresizingMaskIntoConstraints = NO;
    wifiIcon.image = [UIImage systemImageNamed:@"wifi"];
    wifiIcon.tintColor = [UIColor systemBlueColor];
    wifiIcon.contentMode = UIViewContentModeScaleAspectFit;
    [containerView addSubview:wifiIcon];

    // WiFi名称标签
    self.wifiNameLabel = [[UILabel alloc] init];
    self.wifiNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.wifiNameLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.wifiNameLabel.textColor = [UIColor labelColor];
    [containerView addSubview:self.wifiNameLabel];

    // 快捷指令标签
    self.shortcutNameLabel = [[UILabel alloc] init];
    self.shortcutNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.shortcutNameLabel.font = [UIFont systemFontOfSize:14];
    self.shortcutNameLabel.textColor = [UIColor secondaryLabelColor];
    [containerView addSubview:self.shortcutNameLabel];

    // 时段标签
    self.scheduleLabel = [[UILabel alloc] init];
    self.scheduleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.scheduleLabel.font = [UIFont systemFontOfSize:12];
    self.scheduleLabel.textColor = [UIColor tertiaryLabelColor];
    self.scheduleLabel.backgroundColor = [UIColor systemGray5Color];
    self.scheduleLabel.layer.cornerRadius = 4;
    self.scheduleLabel.clipsToBounds = YES;
    self.scheduleLabel.textAlignment = NSTextAlignmentCenter;
    [containerView addSubview:self.scheduleLabel];

    // 启用开关
    self.enabledSwitch = [[UISwitch alloc] init];
    self.enabledSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    self.enabledSwitch.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [self.enabledSwitch addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
    [containerView addSubview:self.enabledSwitch];

    // 编辑按钮
    self.editButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.editButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.editButton setImage:[UIImage systemImageNamed:@"pencil.circle"] forState:UIControlStateNormal];
    self.editButton.tintColor = [UIColor systemBlueColor];
    [self.editButton addTarget:self action:@selector(editButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:self.editButton];

    // 删除按钮
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.deleteButton setImage:[UIImage systemImageNamed:@"trash.circle"] forState:UIControlStateNormal];
    self.deleteButton.tintColor = [UIColor systemRedColor];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:self.deleteButton];

    // 分隔线
    UIView *separator = [[UIView alloc] init];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    separator.backgroundColor = [UIColor separatorColor];
    [containerView addSubview:separator];

    // 添加约束
    [NSLayoutConstraint activateConstraints:@[
        // 容器
        [containerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
        [containerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [containerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
        [containerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8],

        // WiFi图标
        [wifiIcon.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:8],
        [wifiIcon.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:12],
        [wifiIcon.widthAnchor constraintEqualToConstant:24],
        [wifiIcon.heightAnchor constraintEqualToConstant:24],

        // WiFi名称
        [self.wifiNameLabel.leadingAnchor constraintEqualToAnchor:wifiIcon.trailingAnchor constant:10],
        [self.wifiNameLabel.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:10],
        [self.wifiNameLabel.trailingAnchor constraintEqualToAnchor:self.enabledSwitch.leadingAnchor constant:-10],

        // 快捷指令名称
        [self.shortcutNameLabel.leadingAnchor constraintEqualToAnchor:self.wifiNameLabel.leadingAnchor],
        [self.shortcutNameLabel.topAnchor constraintEqualToAnchor:self.wifiNameLabel.bottomAnchor constant:4],
        [self.shortcutNameLabel.trailingAnchor constraintEqualToAnchor:self.enabledSwitch.leadingAnchor constant:-10],

        // 时段标签
        [self.scheduleLabel.leadingAnchor constraintEqualToAnchor:self.wifiNameLabel.leadingAnchor],
        [self.scheduleLabel.topAnchor constraintEqualToAnchor:self.shortcutNameLabel.bottomAnchor constant:6],
        [self.scheduleLabel.widthAnchor constraintEqualToConstant:60],
        [self.scheduleLabel.heightAnchor constraintEqualToConstant:20],

        // 启用开关
        [self.enabledSwitch.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-8],
        [self.enabledSwitch.centerYAnchor constraintEqualToAnchor:containerView.centerYAnchor constant:-8],

        // 编辑按钮
        [self.editButton.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-8],
        [self.editButton.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor constant:-8],
        [self.editButton.widthAnchor constraintEqualToConstant:28],
        [self.editButton.heightAnchor constraintEqualToConstant:28],

        // 删除按钮
        [self.deleteButton.trailingAnchor constraintEqualToAnchor:self.editButton.leadingAnchor constant:-12],
        [self.deleteButton.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor constant:-8],
        [self.deleteButton.widthAnchor constraintEqualToConstant:28],
        [self.deleteButton.heightAnchor constraintEqualToConstant:28],

        // 分隔线
        [separator.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:8],
        [separator.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-8],
        [separator.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],
        [separator.heightAnchor constraintEqualToConstant:0.5]
    ]];
}

#pragma mark - Configuration

- (void)configureWithRule:(id)rule {
    if ([rule isKindOfClass:[WIFIRule class]]) {
        WIFIRule *wifiRule = (WIFIRule *)rule;
        self.wifiNameLabel.text = wifiRule.ssid;
        self.shortcutNameLabel.text = [NSString stringWithFormat:@"▶ %@", wifiRule.shortcutName];
        self.enabledSwitch.on = wifiRule.isEnabled;

        // 设置时段文字
        NSString *scheduleText = @"总是";
        switch (wifiRule.scheduleType) {
            case WIFIScheduleTypeAlways:
                scheduleText = @"总是";
                break;
            case WIFIScheduleTypeWeekday:
                scheduleText = @"工作日";
                break;
            case WIFIScheduleTypeWeekend:
                scheduleText = @"周末";
                break;
        }
        self.scheduleLabel.text = [NSString stringWithFormat:@" %@ ", scheduleText];

        // 根据启用状态调整外观
        if (wifiRule.isEnabled) {
            self.wifiNameLabel.textColor = [UIColor labelColor];
            self.shortcutNameLabel.textColor = [UIColor secondaryLabelColor];
            self.contentView.alpha = 1.0;
        } else {
            self.wifiNameLabel.textColor = [UIColor tertiaryLabelColor];
            self.shortcutNameLabel.textColor = [UIColor quaternaryLabelColor];
            self.contentView.alpha = 0.6;
        }
    }
}

#pragma mark - Actions

- (void)switchToggled:(UISwitch *)sender {
    [UIView animateWithDuration:0.2 animations:^{
        self.contentView.alpha = sender.on ? 1.0 : 0.6;
    }];

    if ([self.delegate respondsToSelector:@selector(ruleCellDidToggleEnabled:)]) {
        [self.delegate ruleCellDidToggleEnabled:self];
    }
}

- (void)editButtonTapped:(UIButton *)sender {
    // 添加点击动画
    [UIView animateWithDuration:0.1 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];

    if ([self.delegate respondsToSelector:@selector(ruleCellDidTapEdit:)]) {
        [self.delegate ruleCellDidTapEdit:self];
    }
}

- (void)deleteButtonTapped:(UIButton *)sender {
    // 添加点击动画
    [UIView animateWithDuration:0.1 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];

    if ([self.delegate respondsToSelector:@selector(ruleCellDidTapDelete:)]) {
        [self.delegate ruleCellDidTapDelete:self];
    }
}

#pragma mark - Reuse

- (void)prepareForReuse {
    [super prepareForReuse];
    self.wifiNameLabel.text = nil;
    self.shortcutNameLabel.text = nil;
    self.scheduleLabel.text = nil;
    self.enabledSwitch.on = YES;
    self.contentView.alpha = 1.0;
}

@end
