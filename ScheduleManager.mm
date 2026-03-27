//
//  ScheduleManager.mm
//  WiFiAutoShortcutLauncher
//
//  WiFi自动快捷指令启动器 - 时段管理模块实现
//

#import "ScheduleManager.h"
#import "WIFIRule.h"

@implementation WIFISchedule

#pragma mark - Initialization

+ (instancetype)defaultSchedule {
    WIFISchedule *schedule = [[WIFISchedule alloc] init];
    schedule.weekdayActive = YES;
    schedule.weekdayStartTime = @"09:00";
    schedule.weekdayEndTime = @"18:00";
    schedule.weekendActive = NO;
    schedule.weekendStartTime = @"10:00";
    schedule.weekendEndTime = @"20:00";
    schedule.inactiveStartTime = @"23:00";
    schedule.inactiveEndTime = @"06:00";
    return schedule;
}

#pragma mark - NSCoding / NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:self.weekdayActive forKey:@"weekdayActive"];
    [coder encodeObject:self.weekdayStartTime forKey:@"weekdayStartTime"];
    [coder encodeObject:self.weekdayEndTime forKey:@"weekdayEndTime"];
    [coder encodeBool:self.weekendActive forKey:@"weekendActive"];
    [coder encodeObject:self.weekendStartTime forKey:@"weekendStartTime"];
    [coder encodeObject:self.weekendEndTime forKey:@"weekendEndTime"];
    [coder encodeObject:self.inactiveStartTime forKey:@"inactiveStartTime"];
    [coder encodeObject:self.inactiveEndTime forKey:@"inactiveEndTime"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _weekdayActive = [coder decodeBoolForKey:@"weekdayActive"];
        _weekdayStartTime = [coder decodeObjectOfClass:[NSString class] forKey:@"weekdayStartTime"] ?: @"09:00";
        _weekdayEndTime = [coder decodeObjectOfClass:[NSString class] forKey:@"weekdayEndTime"] ?: @"18:00";
        _weekendActive = [coder decodeBoolForKey:@"weekendActive"];
        _weekendStartTime = [coder decodeObjectOfClass:[NSString class] forKey:@"weekendStartTime"] ?: @"10:00";
        _weekendEndTime = [coder decodeObjectOfClass:[NSString class] forKey:@"weekendEndTime"] ?: @"20:00";
        _inactiveStartTime = [coder decodeObjectOfClass:[NSString class] forKey:@"inactiveStartTime"] ?: @"23:00";
        _inactiveEndTime = [coder decodeObjectOfClass:[NSString class] forKey:@"inactiveEndTime"] ?: @"06:00";
    }
    return self;
}

#pragma mark - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<WIFISchedule: Weekday[%@ %@-%@] Weekend[%@ %@-%@] Inactive[%@-%@]",
            self.weekdayActive ? @"ON" : @"OFF",
            self.weekdayStartTime,
            self.weekdayEndTime,
            self.weekendActive ? @"ON" : @"OFF",
            self.weekendStartTime,
            self.weekendEndTime,
            self.inactiveStartTime,
            self.inactiveEndTime];
}

@end

#pragma mark - ScheduleManager

@implementation ScheduleManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static ScheduleManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ScheduleManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _schedule = [WIFISchedule defaultSchedule];
    }
    return self;
}

#pragma mark - Time Period Checks

- (BOOL)isCurrentlyActiveForScheduleType:(NSInteger)scheduleType {
    return [self isDate:[NSDate date] activeForScheduleType:scheduleType];
}

- (BOOL)isDate:(NSDate *)date activeForScheduleType:(NSInteger)scheduleType {
    // 首先检查是否在禁止时段
    if ([self isDateInInactivePeriod:date]) {
        return NO;
    }

    // 如果是始终生效模式
    if (scheduleType == WIFIScheduleTypeAlways) {
        return YES;
    }

    NSInteger weekday = [self currentWeekdayForDate:date];

    if (scheduleType == WIFIScheduleTypeWeekday) {
        // 工作日模式：周一到周五（weekday 2-6）
        if (weekday >= 2 && weekday <= 6) {
            return [self isDateInActivePeriod:date startTime:self.schedule.weekdayStartTime endTime:self.schedule.weekdayEndTime];
        }
        return NO;
    }

    if (scheduleType == WIFIScheduleTypeWeekend) {
        // 周末模式：周六周日（weekday 1或7）
        if (weekday == 1 || weekday == 7) {
            return [self isDateInActivePeriod:date startTime:self.schedule.weekendStartTime endTime:self.schedule.weekendEndTime];
        }
        return NO;
    }

    return NO;
}

- (BOOL)isDateInActivePeriod:(NSDate *)date startTime:(NSString *)startTime endTime:(NSString *)endTime {
    if (!startTime || !endTime || startTime.length == 0 || endTime.length == 0) {
        return YES; // 如果没有配置时间，默认生效
    }

    NSDateComponents *startComponents = [self componentsFromTimeString:startTime referenceDate:date];
    NSDateComponents *endComponents = [self componentsFromTimeString:endTime referenceDate:date];
    NSDateComponents *currentComponents = [self componentsFromTimeString:[self timeStringFromDate:date] referenceDate:date];

    if (!startComponents || !endComponents || !currentComponents) {
        return YES;
    }

    NSInteger startMinutes = startComponents.hour * 60 + startComponents.minute;
    NSInteger endMinutes = endComponents.hour * 60 + endComponents.minute;
    NSInteger currentMinutes = currentComponents.hour * 60 + currentComponents.minute;

    // 处理跨天情况（例如 23:00 - 06:00）
    if (endMinutes < startMinutes) {
        // 跨天情况
        return (currentMinutes >= startMinutes) || (currentMinutes < endMinutes);
    } else {
        // 同一天情况
        return (currentMinutes >= startMinutes) && (currentMinutes < endMinutes);
    }
}

- (BOOL)isDateInInactivePeriod:(NSDate *)date {
    if (!self.schedule.inactiveStartTime || !self.schedule.inactiveEndTime ||
        self.schedule.inactiveStartTime.length == 0 || self.schedule.inactiveEndTime.length == 0) {
        return NO; // 如果没有配置禁止时段，默认不禁用
    }

    return [self isDateInActivePeriod:date
                           startTime:self.schedule.inactiveStartTime
                             endTime:self.schedule.inactiveEndTime];
}

#pragma mark - Weekday Helpers

- (NSInteger)currentWeekday {
    return [self currentWeekdayForDate:[NSDate date]];
}

- (NSInteger)currentWeekdayForDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitWeekday fromDate:date];
    return components.weekday; // 1=周日，2=周一，...，7=周六
}

- (BOOL)isWeekday {
    NSInteger weekday = [self currentWeekday];
    return (weekday >= 2 && weekday <= 6);
}

- (BOOL)isWeekend {
    NSInteger weekday = [self currentWeekday];
    return (weekday == 1 || weekday == 7);
}

#pragma mark - Time String Conversion

- (NSDateComponents *)componentsFromTimeString:(NSString *)timeString referenceDate:(NSDate *)referenceDate {
    if (!timeString || timeString.length == 0) {
        return nil;
    }

    NSArray<NSString *> *parts = [timeString componentsSeparatedByString:@":"];
    if (parts.count != 2) {
        return nil;
    }

    NSInteger hours = [parts[0] integerValue];
    NSInteger minutes = [parts[1] integerValue];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                                               fromDate:referenceDate];
    components.hour = hours;
    components.minute = minutes;
    components.second = 0;

    return components;
}

- (NSString *)timeStringFromDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];

    return [NSString stringWithFormat:@"%02ld:%02ld", (long)components.hour, (long)components.minute];
}

#pragma mark - Schedule Update

- (void)updateSchedule:(WIFISchedule *)schedule {
    if (schedule) {
        self.schedule = schedule;
    }
}

@end
