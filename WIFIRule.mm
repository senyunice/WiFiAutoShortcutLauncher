//
//  WIFIRule.mm
//  WiFiAutoShortcutLauncher
//
//  WiFi自动快捷指令启动器 - 规则配置模型实现
//

#import "WIFIRule.h"

@implementation WIFIRule

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _ssid = @"";
        _shortcutIdentifier = @"";
        _shortcutName = @"";
        _isEnabled = YES;
        _scheduleType = WIFIScheduleTypeAlways;
    }
    return self;
}

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

#pragma mark - NSCoding / NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.ssid forKey:@"ssid"];
    [coder encodeObject:self.shortcutIdentifier forKey:@"shortcutIdentifier"];
    [coder encodeObject:self.shortcutName forKey:@"shortcutName"];
    [coder encodeBool:self.isEnabled forKey:@"isEnabled"];
    [coder encodeInteger:self.scheduleType forKey:@"scheduleType"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _ssid = [coder decodeObjectOfClass:[NSString class] forKey:@"ssid"] ?: @"";
        _shortcutIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"shortcutIdentifier"] ?: @"";
        _shortcutName = [coder decodeObjectOfClass:[NSString class] forKey:@"shortcutName"] ?: @"";
        _isEnabled = [coder decodeBoolForKey:@"isEnabled"];
        _scheduleType = [coder decodeIntegerForKey:@"scheduleType"];
    }
    return self;
}

#pragma mark - Dictionary Conversion

- (NSDictionary *)toDictionary {
    return @{
        @"ssid": self.ssid ?: @"",
        @"shortcutIdentifier": self.shortcutIdentifier ?: @"",
        @"shortcutName": self.shortcutName ?: @"",
        @"isEnabled": @(self.isEnabled),
        @"scheduleType": @(self.scheduleType)
    };
}

+ (instancetype)ruleFromDictionary:(NSDictionary *)dictionary {
    if (!dictionary || ![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    WIFIRule *rule = [[WIFIRule alloc] init];
    rule.ssid = dictionary[@"ssid"] ?: @"";
    rule.shortcutIdentifier = dictionary[@"shortcutIdentifier"] ?: @"";
    rule.shortcutName = dictionary[@"shortcutName"] ?: @"";

    id isEnabledValue = dictionary[@"isEnabled"];
    if (isEnabledValue) {
        rule.isEnabled = [isEnabledValue boolValue];
    }

    id scheduleTypeValue = dictionary[@"scheduleType"];
    if (scheduleTypeValue) {
        if ([scheduleTypeValue isKindOfClass:[NSString class]]) {
            [rule setScheduleTypeFromString:scheduleTypeValue];
        } else if ([scheduleTypeValue isKindOfClass:[NSNumber class]]) {
            rule.scheduleType = [scheduleTypeValue integerValue];
        }
    }

    return rule;
}

#pragma mark - Schedule Type Helpers

- (NSString *)scheduleTypeString {
    switch (self.scheduleType) {
        case WIFIScheduleTypeAlways:
            return @"always";
        case WIFIScheduleTypeWeekday:
            return @"weekday";
        case WIFIScheduleTypeWeekend:
            return @"weekend";
        default:
            return @"always";
    }
}

- (void)setScheduleTypeFromString:(NSString *)string {
    if ([string isEqualToString:@"always"]) {
        self.scheduleType = WIFIScheduleTypeAlways;
    } else if ([string isEqualToString:@"weekday"]) {
        self.scheduleType = WIFIScheduleTypeWeekday;
    } else if ([string isEqualToString:@"weekend"]) {
        self.scheduleType = WIFIScheduleTypeWeekend;
    } else {
        self.scheduleType = WIFIScheduleTypeAlways;
    }
}

#pragma mark - Description

- (NSString *)description {
    return [NSString stringWithFormat:@"<WIFIRule: %p | SSID: %@ | Shortcut: %@ | Enabled: %@ | Schedule: %@>",
            self,
            self.ssid,
            self.shortcutName,
            self.isEnabled ? @"YES" : @"NO",
            [self scheduleTypeString]];
}

@end
