//
//  ConfigManager.mm
//  WiFiAutoShortcutLauncher
//
//  WiFi自动快捷指令启动器 - 配置管理模块实现
//

#import "ConfigManager.h"

static NSString * const kWiFiRulesKey = @"WiFiAutoShortcutLauncher_Rules";
static NSString * const kScheduleKey = @"WiFiAutoShortcutLauncher_Schedule";

@interface ConfigManager ()

@property (nonatomic, strong) NSMutableArray<WIFIRule *> *cachedRules;
@property (nonatomic, strong) WIFISchedule *cachedSchedule;

@end

@implementation ConfigManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static ConfigManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ConfigManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadData];
    }
    return self;
}

#pragma mark - Private Methods

- (void)loadData {
    // 加载规则列表
    NSArray *storedRules = [[NSUserDefaults standardUserDefaults] objectForKey:kWiFiRulesKey];
    if (storedRules) {
        NSMutableArray *rules = [NSMutableArray array];
        for (NSDictionary *dict in storedRules) {
            WIFIRule *rule = [WIFIRule ruleFromDictionary:dict];
            if (rule) {
                [rules addObject:rule];
            }
        }
        _cachedRules = rules;
    } else {
        _cachedRules = [NSMutableArray array];
    }

    // 加载时段配置
    NSData *scheduleData = [[NSUserDefaults standardUserDefaults] objectForKey:kScheduleKey];
    if (scheduleData) {
        NSError *error = nil;
        WIFISchedule *schedule = [NSKeyedUnarchiver unarchivedObjectOfClass:[WIFISchedule class] fromData:scheduleData error:&error];
        if (schedule && !error) {
            _cachedSchedule = schedule;
        } else {
            _cachedSchedule = [WIFISchedule defaultSchedule];
        }
    } else {
        _cachedSchedule = [WIFISchedule defaultSchedule];
    }

    // 更新ScheduleManager的全局配置
    [[ScheduleManager sharedManager] updateSchedule:_cachedSchedule];
}

- (void)saveRulesInternal {
    NSMutableArray *dictArray = [NSMutableArray array];
    for (WIFIRule *rule in self.cachedRules) {
        [dictArray addObject:[rule toDictionary]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:dictArray forKey:kWiFiRulesKey];
}

- (void)saveScheduleInternal {
    NSError *error = nil;
    NSData *scheduleData = [NSKeyedArchiver archivedDataWithRootObject:self.cachedSchedule
                                                 requiringSecureCoding:YES
                                                                 error:&error];
    if (scheduleData && !error) {
        [[NSUserDefaults standardUserDefaults] setObject:scheduleData forKey:kScheduleKey];
    }
}

#pragma mark - WiFi规则管理

- (NSArray<WIFIRule *> *)allRules {
    return [self.cachedRules copy];
}

- (NSArray<WIFIRule *> *)enabledRules {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isEnabled == YES"];
    return [self.cachedRules filteredArrayUsingPredicate:predicate];
}

- (nullable WIFIRule *)ruleForSSID:(NSString *)ssid {
    if (!ssid || ssid.length == 0) {
        return nil;
    }

    for (WIFIRule *rule in self.cachedRules) {
        if ([rule.ssid isEqualToString:ssid]) {
            return rule;
        }
    }
    return nil;
}

- (void)addRule:(WIFIRule *)rule {
    if (!rule || !rule.ssid || rule.ssid.length == 0) {
        return;
    }

    // 检查是否已存在相同SSID的规则
    WIFIRule *existingRule = [self ruleForSSID:rule.ssid];
    if (existingRule) {
        // 如果存在，更新它
        NSInteger index = [self.cachedRules indexOfObject:existingRule];
        if (index != NSNotFound) {
            [self.cachedRules replaceObjectAtIndex:index withObject:rule];
        }
    } else {
        // 添加新规则
        [self.cachedRules addObject:rule];
    }

    [self saveRulesInternal];
    [self synchronize];
}

- (void)updateRule:(WIFIRule *)rule {
    if (!rule || !rule.ssid || rule.ssid.length == 0) {
        return;
    }

    WIFIRule *existingRule = [self ruleForSSID:rule.ssid];
    if (existingRule) {
        NSInteger index = [self.cachedRules indexOfObject:existingRule];
        if (index != NSNotFound) {
            [self.cachedRules replaceObjectAtIndex:index withObject:rule];
            [self saveRulesInternal];
            [self synchronize];
        }
    }
}

- (void)removeRule:(WIFIRule *)rule {
    if (!rule) {
        return;
    }

    [self removeRuleForSSID:rule.ssid];
}

- (void)removeRuleForSSID:(NSString *)ssid {
    if (!ssid || ssid.length == 0) {
        return;
    }

    WIFIRule *ruleToRemove = nil;
    for (WIFIRule *rule in self.cachedRules) {
        if ([rule.ssid isEqualToString:ssid]) {
            ruleToRemove = rule;
            break;
        }
    }

    if (ruleToRemove) {
        [self.cachedRules removeObject:ruleToRemove];
        [self saveRulesInternal];
        [self synchronize];
    }
}

- (void)clearAllRules {
    [self.cachedRules removeAllObjects];
    [self saveRulesInternal];
    [self synchronize];
}

- (void)replaceAllRules:(NSArray<WIFIRule *> *)rules {
    if (rules) {
        self.cachedRules = [rules mutableCopy];
    } else {
        self.cachedRules = [NSMutableArray array];
    }
    [self saveRulesInternal];
    [self synchronize];
}

#pragma mark - 时段配置管理

- (WIFISchedule *)schedule {
    return self.cachedSchedule;
}

- (void)saveSchedule:(WIFISchedule *)schedule {
    if (!schedule) {
        return;
    }

    self.cachedSchedule = schedule;
    [self saveScheduleInternal];

    // 更新ScheduleManager的全局配置
    [[ScheduleManager sharedManager] updateSchedule:schedule];

    [self synchronize];
}

- (void)resetScheduleToDefault {
    self.cachedSchedule = [WIFISchedule defaultSchedule];
    [self saveScheduleInternal];
    [[ScheduleManager sharedManager] updateSchedule:self.cachedSchedule];
    [self synchronize];
}

#pragma mark - Persistence

- (void)synchronize {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)hasStoredData {
    NSArray *storedRules = [[NSUserDefaults standardUserDefaults] objectForKey:kWiFiRulesKey];
    NSData *scheduleData = [[NSUserDefaults standardUserDefaults] objectForKey:kScheduleKey];

    return (storedRules.count > 0) || (scheduleData != nil);
}

@end
