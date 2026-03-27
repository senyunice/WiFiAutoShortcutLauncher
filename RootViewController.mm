//
//  RootViewController.mm
//  WiFiAutoShortcutLauncher
//
//  WiFi自动快捷指令启动器 - 主设置界面
//

#import "RootViewController.h"
#import "WIFIRule.h"
#import "WiFiRuleCell.h"
#import "SchedulePickerViewController.h"
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 blue:((float)(rgbValue & 0x0000FF))/255.0 alpha:1.0]
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static NSString *const kEnabledKey = @"WiFiAutoShortcutLauncherEnabled";
static NSString *const kWeekdayModeKey = @"WiFiAutoShortcutLauncherWeekdayMode";
static NSString *const kWeekendModeKey = @"WiFiAutoShortcutLauncherWeekendMode";
static NSString *const kDisabledStartTimeKey = @"WiFiAutoShortcutLauncherDisabledStartTime";
static NSString *const kDisabledEndTimeKey = @"WiFiAutoShortcutLauncherDisabledEndTime";
static NSString *const kRulesKey = @"WiFiAutoShortcutLauncherRules";
static NSString *const kPreferenceIdentifier = @"com.wifiautoshortcut.launcher";

@interface RootViewController () <WiFiRuleCellDelegate, UITextFieldDelegate, SchedulePickerDelegate>

@property (nonatomic, strong) UITableView *mainTableView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) UISwitch *masterSwitch;
@property (nonatomic, strong) UILabel *masterSwitchLabel;
@property (nonatomic, strong) UIView *addButtonContainer;
@property (nonatomic, strong) UITextField *wifiNameInputField;
@property (nonatomic, strong) UITextField *shortcutInputField;
@property (nonatomic, strong) UIDatePicker *disabledStartPicker;
@property (nonatomic, strong) UIDatePicker *disabledEndPicker;
@property (nonatomic, strong) UIView *addRuleOverlay;
@property (nonatomic, strong) UIView *currentlyEditingCell;

@end

@implementation RootViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigationBar];
    [self loadPreferences];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadPreferences];
    [self.mainTableView reloadData];
}

#pragma mark - Setup

- (void)setupNavigationBar {
    self.title = @"WiFi自动快捷指令启动器";
    self.navigationItem.title = @"WiFi自动快捷指令启动器";

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
        self.navigationController.navigationBar.prefersLargeTitles = YES;
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    }

    // 添加关于按钮
    UIBarButtonItem *aboutButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"info.circle"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(showAbout)];
    self.navigationItem.rightBarButtonItem = aboutButton;
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    // 创建主表格
    self.mainTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.mainTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mainTableView.delegate = self;
    self.mainTableView.dataSource = self;
    self.mainTableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self.mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.mainTableView registerClass:[WiFiRuleCell class] forCellReuseIdentifier:@"RuleCell"];
    [self.view addSubview:self.mainTableView];

    // 设置头部视图
    [self setupHeaderView];

    // 设置底部视图
    [self setupFooterView];
}

- (void)setupHeaderView {
    // 插件开关头部
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 80)];

    UIView *masterSwitchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    masterSwitchContainer.backgroundColor = [UIColor systemBackgroundColor];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 200, 20)];
    titleLabel.text = @"启用插件";
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    [masterSwitchContainer addSubview:titleLabel];

    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 32, 200, 16)];
    subtitleLabel.text = @"开启后根据WiFi自动执行快捷指令";
    subtitleLabel.font = [UIFont systemFontOfSize:13];
    subtitleLabel.textColor = [UIColor secondaryLabelColor];
    [masterSwitchContainer addSubview:subtitleLabel];

    self.masterSwitch = [[UISwitch alloc] init];
    self.masterSwitch.frame = CGRectMake(self.view.bounds.size.width - 70, 15, 51, 31);
    [self.masterSwitch addTarget:self action:@selector(masterSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.masterSwitch.on = self.isEnabled;
    [masterSwitchContainer addSubview:self.masterSwitch];

    [headerContainer addSubview:masterSwitchContainer];

    self.mainTableView.tableHeaderView = headerContainer;
}

- (void)setupFooterView {
    // 关于信息
    UIView *footerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 80)];

    UILabel *versionLabel = [[UILabel alloc] init];
    versionLabel.text = @"WiFi自动快捷指令启动器 v1.0.0";
    versionLabel.font = [UIFont systemFontOfSize:13];
    versionLabel.textColor = [UIColor tertiaryLabelColor];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.frame = CGRectMake(0, 20, self.view.bounds.size.width, 20);
    [footerContainer addSubview:versionLabel];

    UILabel *copyrightLabel = [[UILabel alloc] init];
    copyrightLabel.text = @"© 2024 All Rights Reserved";
    copyrightLabel.font = [UIFont systemFontOfSize:11];
    copyrightLabel.textColor = [UIColor quaternaryLabelColor];
    copyrightLabel.textAlignment = NSTextAlignmentCenter;
    copyrightLabel.frame = CGRectMake(0, 44, self.view.bounds.size.width, 16);
    [footerContainer addSubview:copyrightLabel];

    self.mainTableView.tableFooterView = footerContainer;
}

#pragma mark - Preferences

- (NSString *)getPreferencePath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    path = [path stringByAppendingPathComponent:@"Preferences"];
    path = [path stringByAppendingPathComponent:kPreferenceIdentifier];
    path = [path stringByAppendingPathExtension:@"plist"];
    return path;
}

- (void)loadPreferences {
    NSString *path = [self getPreferencePath];
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:path];

    if (prefs) {
        self.isEnabled = [prefs[kEnabledKey] boolValue];
        self.weekdayModeEnabled = [prefs[kWeekdayModeKey] boolValue];
        self.weekendModeEnabled = [prefs[kWeekendModeKey] boolValue];
        self.disabledStartTime = prefs[kDisabledStartTimeKey] ?: @"22:00";
        self.disabledEndTime = prefs[kDisabledEndTimeKey] ?: @"08:00";

        NSArray *rulesArray = prefs[kRulesKey];
        if (rulesArray) {
            NSMutableArray *loadedRules = [NSMutableArray array];
            for (NSDictionary *dict in rulesArray) {
                WIFIRule *rule = [WIFIRule ruleFromDictionary:dict];
                if (rule) {
                    [loadedRules addObject:rule];
                }
            }
            self.rules = loadedRules;
        } else {
            self.rules = [NSMutableArray array];
        }
    } else {
        self.isEnabled = YES;
        self.weekdayModeEnabled = YES;
        self.weekendModeEnabled = YES;
        self.disabledStartTime = @"22:00";
        self.disabledEndTime = @"08:00";
        self.rules = [NSMutableArray array];
    }
}

- (void)savePreferences {
    NSMutableArray *rulesArray = [NSMutableArray array];
    for (WIFIRule *rule in self.rules) {
        [rulesArray addObject:[rule toDictionary]];
    }

    NSDictionary *prefs = @{
        kEnabledKey: @(self.isEnabled),
        kWeekdayModeKey: @(self.weekdayModeEnabled),
        kWeekendModeKey: @(self.weekendModeEnabled),
        kDisabledStartTimeKey: self.disabledStartTime ?: @"22:00",
        kDisabledEndTimeKey: self.disabledEndTime ?: @"08:00",
        kRulesKey: rulesArray
    };

    NSString *path = [self getPreferencePath];
    NSString *directory = [path stringByDeletingLastPathComponent];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:directory]) {
        [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    [prefs writeToFile:path atomically:YES];
}

- (void)reloadData {
    [self loadPreferences];
    [self.mainTableView reloadData];
}

#pragma mark - Actions

- (void)masterSwitchChanged:(UISwitch *)sender {
    self.isEnabled = sender.on;
    [self savePreferences];

    // 动画反馈
    [UIView animateWithDuration:0.3 animations:^{
        self.mainTableView.alpha = sender.on ? 1.0 : 0.6;
    }];
}

- (void)addRule {
    [self showAddRuleOverlay];
}

- (void)editRule:(NSInteger)index {
    if (index < 0 || index >= self.rules.count) return;

    WIFIRule *rule = self.rules[index];
    [self showEditRuleOverlayWithRule:rule atIndex:index];
}

- (void)deleteRule:(NSInteger)index {
    if (index < 0 || index >= self.rules.count) return;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"删除规则"
                                                                   message:@"确定要删除这条规则吗？"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.rules removeObjectAtIndex:index];
        [self savePreferences];

        [UIView animateWithDuration:0.3 animations:^{
            [self.mainTableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index + 4 inSection:0]]
                                      withRowAnimation:UITableViewRowAnimationFade];
        } completion:^(BOOL finished) {
            [self.mainTableView reloadData];
        }];
    }];

    [alert addAction:cancelAction];
    [alert addAction:deleteAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAbout {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"关于"
                                                                   message:@"WiFi自动快捷指令启动器\n\n版本: 1.0.0\n\n根据连接的WiFi网络自动执行快捷指令的越狱插件。\n\n检测频率: 5秒\n\n© 2024 All Rights Reserved"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Add/Edit Rule Overlay

- (void)showAddRuleOverlay {
    [self showRuleOverlayWithRule:nil atIndex:-1];
}

- (void)showEditRuleOverlayWithRule:(WIFIRule *)rule atIndex:(NSInteger)index {
    [self showRuleOverlayWithRule:rule atIndex:index];
}

- (void)showRuleOverlayWithRule:(WIFIRule *)rule atIndex:(NSInteger)index {
    // 创建半透明背景
    UIView *overlayBg = [[UIView alloc] initWithFrame:self.view.bounds];
    overlayBg.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    overlayBg.alpha = 0;
    [self.view addSubview:overlayBg];

    // 创建表单容器
    CGFloat formWidth = self.view.bounds.size.width - 40;
    CGFloat formHeight = 380;
    CGFloat formX = 20;
    CGFloat formY = (self.view.bounds.size.height - formHeight) / 2;

    UIView *formContainer = [[UIView alloc] initWithFrame:CGRectMake(formX, formY, formWidth, formHeight)];
    formContainer.backgroundColor = [UIColor systemBackgroundColor];
    formContainer.layer.cornerRadius = 14;
    formContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    formContainer.layer.shadowOffset = CGSizeMake(0, 4);
    formContainer.layer.shadowRadius = 10;
    formContainer.layer.shadowOpacity = 0.3;
    formContainer.transform = CGAffineTransformMakeScale(0.9, 0.9);
    formContainer.alpha = 0;
    [self.view addSubview:formContainer];

    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, formWidth - 40, 25)];
    titleLabel.text = rule ? @"编辑规则" : @"添加规则";
    titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [formContainer addSubview:titleLabel];

    // WiFi名称输入
    UILabel *wifiLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, 80, 20)];
    wifiLabel.text = @"WiFi名称";
    wifiLabel.font = [UIFont systemFontOfSize:15];
    [formContainer addSubview:wifiLabel];

    UITextField *wifiTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 78, formWidth - 40, 36)];
    wifiTextField.borderStyle = UITextBorderStyleRoundedRect;
    wifiTextField.placeholder = @"输入WiFi名称";
    wifiTextField.text = rule.ssid ?: @"";
    wifiTextField.delegate = self;
    wifiTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    wifiTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    [formContainer addSubview:wifiTextField];

    // 快捷指令输入
    UILabel *shortcutLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 125, 80, 20)];
    shortcutLabel.text = @"快捷指令";
    shortcutLabel.font = [UIFont systemFontOfSize:15];
    [formContainer addSubview:shortcutLabel];

    UITextField *shortcutTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 148, formWidth - 40, 36)];
    shortcutTextField.borderStyle = UITextBorderStyleRoundedRect;
    shortcutTextField.placeholder = @"输入快捷指令名称";
    shortcutTextField.text = rule.shortcutName ?: @"";
    shortcutTextField.delegate = self;
    [formContainer addSubview:shortcutTextField];

    // 时段选择
    UILabel *scheduleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 195, 80, 20)];
    scheduleLabel.text = @"生效时段";
    scheduleLabel.font = [UIFont systemFontOfSize:15];
    [formContainer addSubview:scheduleLabel];

    UISegmentedControl *scheduleControl = [[UISegmentedControl alloc] initWithItems:@[@"始终", @"工作日", @"周末"]];
    scheduleControl.frame = CGRectMake(20, 218, formWidth - 40, 32);
    scheduleControl.selectedSegmentIndex = rule ? rule.scheduleType : 0;
    [formContainer addSubview:scheduleControl];

    // 启用开关
    UISwitch *enabledSwitch = [[UISwitch alloc] init];
    enabledSwitch.on = rule ? rule.isEnabled : YES;
    enabledSwitch.frame = CGRectMake(formWidth - 71, 265, 51, 31);
    [formContainer addSubview:enabledSwitch];

    UILabel *enabledLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 268, 100, 25)];
    enabledLabel.text = @"启用规则";
    enabledLabel.font = [UIFont systemFontOfSize:15];
    [formContainer addSubview:enabledLabel];

    // 按钮
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.frame = CGRectMake(20, 315, (formWidth - 50) / 2, 44);
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    cancelButton.backgroundColor = [UIColor systemGray5Color];
    cancelButton.layer.cornerRadius = 10;
    [cancelButton addTarget:self action:@selector(dismissOverlay:) forControlEvents:UIControlEventTouchUpInside];
    [formContainer addSubview:cancelButton];

    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    saveButton.frame = CGRectMake(formWidth / 2 + 5, 315, (formWidth - 50) / 2, 44);
    [saveButton setTitle:@"保存" forState:UIControlStateNormal];
    saveButton.backgroundColor = [UIColor systemBlueColor];
    [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveButton.layer.cornerRadius = 10;

    __block WIFIRule *ruleToEdit = rule;
    __block NSInteger editIndex = index;

    [saveButton addAction:[UIButtonAction actionWithHandler:^(UIControl * _Nonnull control) {
        NSString *wifiName = wifiTextField.text;
        NSString *shortcutName = shortcutTextField.text;

        if (wifiName.length == 0 || shortcutName.length == 0) {
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"错误"
                                                                              message:@"请填写WiFi名称和快捷指令名称"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
            [errorAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:errorAlert animated:YES completion:nil];
            return;
        }

        if (editIndex < 0) {
            // 新增规则
            WIFIRule *newRule = [[WIFIRule alloc] initWithSSID:wifiName
                                            shortcutIdentifier:[@"shortcut-" stringByAppendingString:[[NSUUID UUID] UUIDString]]
                                                  shortcutName:shortcutName];
            newRule.isEnabled = enabledSwitch.on;
            newRule.scheduleType = scheduleControl.selectedSegmentIndex;
            [self.rules addObject:newRule];
        } else {
            // 编辑规则
            ruleToEdit.ssid = wifiName;
            ruleToEdit.shortcutName = shortcutName;
            ruleToEdit.isEnabled = enabledSwitch.on;
            ruleToEdit.scheduleType = scheduleControl.selectedSegmentIndex;
        }

        [self savePreferences];

        [UIView animateWithDuration:0.25 animations:^{
            overlayBg.alpha = 0;
            formContainer.alpha = 0;
            formContainer.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:^(BOOL finished) {
            [overlayBg removeFromSuperview];
            [formContainer removeFromSuperview];
            [self.mainTableView reloadData];
        }];
    }] forControlEvents:UIControlEventTouchUpInside];

    [formContainer addSubview:saveButton];

    // 显示动画
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:0 animations:^{
        overlayBg.alpha = 1;
        formContainer.alpha = 1;
        formContainer.transform = CGAffineTransformIdentity;
    } completion:nil];

    // 点击背景关闭
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissOverlay:)];
    [overlayBg addGestureRecognizer:tapGesture];

    self.addRuleOverlay = formContainer;
}

- (void)dismissOverlay:(id)sender {
    UIView *overlayBg = self.addRuleOverlay.superview;
    [UIView animateWithDuration:0.25 animations:^{
        overlayBg.alpha = 0;
        self.addRuleOverlay.alpha = 0;
        self.addRuleOverlay.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [overlayBg removeFromSuperview];
        [self.addRuleOverlay removeFromSuperview];
    }];
}

#pragma mark - WiFiRuleCellDelegate

- (void)ruleCellDidToggleEnabled:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.mainTableView indexPathForCell:cell];
    if (!indexPath) return;

    NSInteger ruleIndex = indexPath.row - 4; // 前面有4个设置项
    if (ruleIndex >= 0 && ruleIndex < self.rules.count) {
        WIFIRule *rule = self.rules[ruleIndex];
        rule.isEnabled = !rule.isEnabled;
        [self savePreferences];
    }
}

- (void)ruleCellDidTapEdit:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.mainTableView indexPathForCell:cell];
    if (!indexPath) return;

    NSInteger ruleIndex = indexPath.row - 4;
    [self editRule:ruleIndex];
}

- (void)ruleCellDidTapDelete:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.mainTableView indexPathForCell:cell];
    if (!indexPath) return;

    NSInteger ruleIndex = indexPath.row - 4;
    [self deleteRule:ruleIndex];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4 + self.rules.count; // 4个设置项 + 规则列表
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.numberOfLines = 0;

    // 清除原有子视图
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }

    if (indexPath.row == 0) {
        // 工作日模式
        cell.textLabel.text = @"工作日模式";
        UISwitch *weekdaySwitch = [[UISwitch alloc] init];
        weekdaySwitch.on = self.weekdayModeEnabled;
        weekdaySwitch.tag = 100;
        [weekdaySwitch addTarget:self action:@selector(weekdaySwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = weekdaySwitch;
    } else if (indexPath.row == 1) {
        // 周末模式
        cell.textLabel.text = @"周末模式";
        UISwitch *weekendSwitch = [[UISwitch alloc] init];
        weekendSwitch.on = self.weekendModeEnabled;
        weekendSwitch.tag = 101;
        [weekendSwitch addTarget:self action:@selector(weekendSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = weekendSwitch;
    } else if (indexPath.row == 2) {
        // 不生效时段设置
        cell.textLabel.text = @"不生效时段";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 20)];
        timeLabel.text = [NSString stringWithFormat:@"%@ - %@", self.disabledStartTime, self.disabledEndTime];
        timeLabel.textColor = [UIColor secondaryLabelColor];
        timeLabel.font = [UIFont systemFontOfSize:14];
        timeLabel.textAlignment = NSTextAlignmentRight;
        cell.accessoryView = timeLabel;
    } else if (indexPath.row == 3) {
        // 添加按钮
        cell.textLabel.text = @"";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        UIView *addContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 50)];
        addContainer.backgroundColor = [UIColor clearColor];

        UIButton *addButton = [UIButton buttonWithType:UIButtonTypeSystem];
        addButton.frame = CGRectMake(20, 5, tableView.bounds.size.width - 40, 44);
        [addButton setTitle:@"+ 添加WiFi规则" forState:UIControlStateNormal];
        addButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        addButton.backgroundColor = [UIColor systemBlueColor];
        [addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        addButton.layer.cornerRadius = 10;
        [addButton addTarget:self action:@selector(addRule) forControlEvents:UIControlEventTouchUpInside];
        [addContainer addSubview:addButton];

        [cell.contentView addSubview:addContainer];
        cell.accessoryView = nil;
    } else {
        // WiFi规则单元格
        WiFiRuleCell *ruleCell = [tableView dequeueReusableCellWithIdentifier:@"RuleCell" forIndexPath:indexPath];
        NSInteger ruleIndex = indexPath.row - 4;
        if (ruleIndex >= 0 && ruleIndex < self.rules.count) {
            WIFIRule *rule = self.rules[ruleIndex];
            [ruleCell configureWithRule:rule];
            ruleCell.delegate = self;
        }
        return ruleCell;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 3) {
        return 60;
    } else if (indexPath.row >= 4) {
        return 90;
    }
    return 50;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"WiFi规则列表";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"检测频率: 固定5秒";
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == 2) {
        // 不生效时段设置
        [self showDisabledTimePicker];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 4) return nil;

    NSInteger ruleIndex = indexPath.row - 4;
    if (ruleIndex < 0 || ruleIndex >= self.rules.count) return nil;

    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                               title:@"删除"
                                                                             handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        [self deleteRule:ruleIndex];
        completionHandler(YES);
    }];

    UIContextualAction *editAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                            title:@"编辑"
                                                                          handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        [self editRule:ruleIndex];
        completionHandler(YES);
    }];
    editAction.backgroundColor = [UIColor systemBlueColor];

    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, editAction]];
}

#pragma mark - Switch Actions

- (void)weekdaySwitchChanged:(UISwitch *)sender {
    self.weekdayModeEnabled = sender.on;
    [self savePreferences];
}

- (void)weekendSwitchChanged:(UISwitch *)sender {
    self.weekendModeEnabled = sender.on;
    [self savePreferences];
}

#pragma mark - Disabled Time Picker

- (void)showDisabledTimePicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置不生效时段"
                                                                   message:@"在该时段内不会执行任何快捷指令"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    // 创建时段选择器视图
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 150)];

    UILabel *startLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 130, 20)];
    startLabel.text = @"开始时间";
    startLabel.textAlignment = NSTextAlignmentCenter;
    startLabel.font = [UIFont systemFontOfSize:14];
    [containerView addSubview:startLabel];

    UILabel *endLabel = [[UILabel alloc] initWithFrame:CGRectMake(140, 10, 130, 20)];
    endLabel.text = @"结束时间";
    endLabel.textAlignment = NSTextAlignmentCenter;
    endLabel.font = [UIFont systemFontOfSize:14];
    [containerView addSubview:endLabel];

    UIDatePicker *startPicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(-10, 35, 130, 100)];
    startPicker.datePickerMode = UIDatePickerModeTime;
    startPicker.preferredDatePickerStyle = UIDatePickerStyleWheels;

    // 解析当前设置的时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm";
    if (self.disabledStartTime) {
        NSDate *date = [formatter dateFromString:self.disabledStartTime];
        if (date) startPicker.date = date;
    }
    [containerView addSubview:startPicker];

    UIDatePicker *endPicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(130, 35, 130, 100)];
    endPicker.datePickerMode = UIDatePickerModeTime;
    endPicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    if (self.disabledEndTime) {
        NSDate *date = [formatter dateFromString:self.disabledEndTime];
        if (date) endPicker.date = date;
    }
    [containerView addSubview:endPicker];

    [alert.view addSubview:containerView];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.disabledStartTime = [formatter stringFromDate:startPicker.date];
        self.disabledEndTime = [formatter stringFromDate:endPicker.date];
        [self savePreferences];
        [self.mainTableView reloadData];
    }];

    [alert addAction:cancelAction];
    [alert addAction:saveAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
