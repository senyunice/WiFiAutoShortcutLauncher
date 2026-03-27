//
//  SchedulePickerViewController.mm
//  WiFiAutoShortcutLauncher
//
//  WiFi自动快捷指令启动器 - 时段选择器
//

#import "SchedulePickerViewController.h"
#import "WIFIRule.h"

@interface SchedulePickerViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *scheduleOptions;
@property (nonatomic, strong) NSArray<NSString *> *scheduleDescriptions;

@end

@implementation SchedulePickerViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupData];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - Setup

- (void)setupData {
    self.scheduleOptions = @[@"始终", @"工作日", @"周末"];
    self.scheduleDescriptions = @[
        @"在任何时间都生效",
        @"仅在周一至周五生效",
        @"仅在周六和周日生效"
    ];
}

- (void)setupUI {
    self.title = @"选择生效时段";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    // 创建导航栏按钮
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(donePressed)];
    self.navigationItem.rightBarButtonItem = doneButton;

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelPressed)];
    self.navigationItem.leftBarButtonItem = cancelButton;

    // 创建表格视图
    CGRect tableFrame = self.view.bounds;
    if (@available(iOS 11.0, *)) {
        // 使用安全区域
    }

    self.tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self.view addSubview:self.tableView];
}

#pragma mark - Navigation Actions

- (void)donePressed {
    if ([self.delegate respondsToSelector:@selector(schedulePicker:didSelectSchedule:)]) {
        [self.delegate schedulePicker:self didSelectSchedule:self.selectedSchedule];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.scheduleOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ScheduleCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ScheduleCell"];
    }

    cell.textLabel.text = self.scheduleOptions[indexPath.row];
    cell.detailTextLabel.text = self.scheduleDescriptions[indexPath.row];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];

    // 选中状态
    if (indexPath.row == self.selectedSchedule) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = [UIColor systemBlueColor];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor labelColor];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"生效时段";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"选择该规则在哪些时间段内生效。工作日模式为周一至周五，周末模式为周六和周日。";
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger previousSelected = self.selectedSchedule;
    self.selectedSchedule = indexPath.row;

    // 动画更新
    [UIView transitionWithView:tableView duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [tableView reloadRowsAtIndexPaths:@[
            [NSIndexPath indexPathForRow:previousSelected inSection:0],
            indexPath
        ] withRowAnimation:UITableViewRowAnimationNone];
    } completion:nil];
}

@end
