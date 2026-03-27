//
//  ConfigManager.h
//  WiFiAutoShortcutLauncher
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WIFIRule;

@interface ConfigManager : NSObject
+ (instancetype)sharedManager;
- (NSArray<WIFIRule *> *)enabledRules;
- (WIFIRule * _Nullable)ruleForSSID:(NSString *)ssid;
@end

NS_ASSUME_NONNULL_END
