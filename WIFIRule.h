//
//  WIFIRule.h
//  WiFiAutoShortcutLauncher
//
//  WiFi自动快捷指令启动器 - 规则配置模型
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WIFIScheduleType) {
    WIFIScheduleTypeAlways = 0,    // 始终生效
    WIFIScheduleTypeWeekday,      // 工作日模式（周一到周五）
    WIFIScheduleTypeWeekend       // 周末模式（周六周日）
};

/// WiFi规则配置模型
@interface WIFIRule : NSObject <NSCoding, NSSecureCoding>

/// WiFi网络名称（SSID）
@property (nonatomic, copy) NSString *ssid;

/// 快捷指令标识符
@property (nonatomic, copy) NSString *shortcutIdentifier;

/// 快捷指令名称
@property (nonatomic, copy) NSString *shortcutName;

/// 是否启用该规则
@property (nonatomic, assign) BOOL isEnabled;

/// 生效时段类型
@property (nonatomic, assign) WIFIScheduleType scheduleType;

/// 创建规则
/// @param ssid WiFi名称
/// @param shortcutIdentifier 快捷指令标识符
/// @param shortcutName 快捷指令名称
- (instancetype)initWithSSID:(NSString *)ssid
          shortcutIdentifier:(NSString *)shortcutIdentifier
                shortcutName:(NSString *)shortcutName;

/// 转换为字典（用于JSON序列化）
- (NSDictionary *)toDictionary;

/// 从字典创建规则
/// @param dictionary 字典数据
+ (nullable instancetype)ruleFromDictionary:(NSDictionary *)dictionary;

/// 获取scheduleType的字符串表示
- (NSString *)scheduleTypeString;

/// 从字符串设置scheduleType
- (void)setScheduleTypeFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
