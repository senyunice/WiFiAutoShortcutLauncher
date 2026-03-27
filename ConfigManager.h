//
//  ConfigManager.h
//  WiFiAutoShortcutLauncher
//
//  WiFi自动快捷指令启动器 - 配置管理模块
//

#import <Foundation/Foundation.h>
#import "WIFIRule.h"
#import "ScheduleManager.h"

NS_ASSUME_NONNULL_BEGIN

/// 配置管理器 - 负责WiFi规则列表和时段配置的持久化存储
@interface ConfigManager : NSObject

/// 获取单例实例
+ (instancetype)sharedManager;

#pragma mark - WiFi规则管理

/// 获取所有WiFi规则
/// @return WiFi规则数组
- (NSArray<WIFIRule *> *)allRules;

/// 获取所有已启用的规则
/// @return 已启用的WiFi规则数组
- (NSArray<WIFIRule *> *)enabledRules;

/// 根据SSID获取规则
/// @param ssid WiFi名称
/// @return 匹配的规则（如果存在）
- (nullable WIFIRule *)ruleForSSID:(NSString *)ssid;

/// 添加WiFi规则
/// @param rule 要添加的规则
- (void)addRule:(WIFIRule *)rule;

/// 更新WiFi规则
/// @param rule 要更新的规则
- (void)updateRule:(WIFIRule *)rule;

/// 删除WiFi规则
/// @param rule 要删除的规则
- (void)removeRule:(WIFIRule *)rule;

/// 删除指定SSID的规则
/// @param ssid WiFi名称
- (void)removeRuleForSSID:(NSString *)ssid;

/// 清除所有规则
- (void)clearAllRules;

/// 替换所有规则
/// @param rules 新的规则数组
- (void)replaceAllRules:(NSArray<WIFIRule *> *)rules;

#pragma mark - 时段配置管理

/// 获取当前时段配置
/// @return 时段配置
- (WIFISchedule *)schedule;

/// 保存时段配置
/// @param schedule 时段配置
- (void)saveSchedule:(WIFISchedule *)schedule;

/// 重置时段配置为默认值
- (void)resetScheduleToDefault;

#pragma mark - 持久化操作

/// 保存所有数据到存储
- (void)synchronize;

/// 判断存储中是否有数据
/// @return 是否有配置数据
- (BOOL)hasStoredData;

@end

NS_ASSUME_NONNULL_END
