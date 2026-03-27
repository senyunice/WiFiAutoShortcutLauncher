//
//  WIFIRule.m
//  WiFiAutoShortcutLauncher
//
//  WiFi自动快捷指令启动器 - 规则配置模型
//

#import "WIFIRule.h"

@implementation WIFIRule

- (instancetype)initWithSSID:(NSString *)ssid
          shortcutIdentifier:(NSString *)shortcutIdentifier
                shortcutName:(NSString *)shortcutName {
    self = [super init];
    if (self) {
        _ssid = [ssid copy];
        _shortcutIdentifier = [shortcutIdentifier copy];
        _shortcutName = [shortcutName copy];
        _isEnabled = YES;
        _scheduleType = WIFIScheduleTypeAlways;
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{
        @"ssid": self.ssid ?: @"",
        @"shortcutIdentifier": self.shortcutIdentifier ?: @"",
        @"shortcutName": self.shortcutName ?: @"",
        @"isEnabled": @(self.isEnabled),
        @"scheduleType": @(self.scheduleType)
    };
}

+ (nullable instancetype)ruleFromDictionary:(NSDictionary *)dictionary {
    if (!dictionary) return nil;

    WIFIRule *rule = [[WIFIRule alloc] initWithSSID:dictionary[@"ssid"]
                                  shortcutIdentifier:dictionary[@"shortcutIdentifier"]
                                        shortcutName:dictionary[@"shortcutName"]];
    rule.isEnabled = [dictionary[@"isEnabled"] boolValue];
    rule.scheduleType = [dictionary[@"scheduleType"] integerValue];
    return rule;
}

- (NSString *)scheduleTypeString {
    switch (self.scheduleType) {
        case WIFIScheduleTypeAlways: return @"总是";
        case WIFIScheduleTypeWeekday: return @"工作日";
        case WIFIScheduleTypeWeekend: return @"周末";
    }
    return @"总是";
}

- (void)setScheduleTypeFromString:(NSString *)string {
    if ([string isEqualToString:@"工作日"]) {
        self.scheduleType = WIFIScheduleTypeWeekday;
    } else if ([string isEqualToString:@"周末"]) {
        self.scheduleType = WIFIScheduleTypeWeekend;
    } else {
        self.scheduleType = WIFIScheduleTypeAlways;
    }
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.ssid forKey:@"ssid"];
    [coder encodeObject:self.shortcutIdentifier forKey:@"shortcutIdentifier"];
    [coder encodeObject:self.shortcutName forKey:@"shortcutName"];
    [coder encodeBool:self.isEnabled forKey:@"isEnabled"];
    [coder encodeInteger:self.scheduleType forKey:@"scheduleType"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _ssid = [coder decodeObjectForKey:@"ssid"];
        _shortcutIdentifier = [coder decodeObjectForKey:@"shortcutIdentifier"];
        _shortcutName = [coder decodeObjectForKey:@"shortcutName"];
        _isEnabled = [coder decodeBoolForKey:@"isEnabled"];
        _scheduleType = [coder decodeIntegerForKey:@"scheduleType"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
