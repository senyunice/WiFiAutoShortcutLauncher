//
//  ConfigManager.mm
//  WiFiAutoShortcutLauncher
//

#import "ConfigManager.h"
#import "WIFIRule.h"

@implementation ConfigManager

+ (instancetype)sharedManager {
    static ConfigManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[ConfigManager alloc] init]; });
    return instance;
}

- (NSArray<WIFIRule *> *)enabledRules {
    return @[];
}

- (WIFIRule *)ruleForSSID:(NSString *)ssid {
    (void)ssid;
    return nil;
}

@end
