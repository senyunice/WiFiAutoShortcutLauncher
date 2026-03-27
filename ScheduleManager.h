//
//  ScheduleManager.h
//  WiFiAutoShortcutLauncher
//
//  WiFi自动快捷指令启动器 - 时段管理模块
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 时段配置模型
@interface WIFISchedule : NSObject <NSCoding, NSSecureCoding>

/// 工作日是否启用
@property (nonatomic, assign) BOOL weekdayActive;

/// 工作日生效开始时间（格式：HH:mm，如 "09:00"）
@property (nonatomic, copy) NSString *weekdayStartTime;

/// 工作日生效结束时间（格式：HH:mm，如 "18:00"）
@property (nonatomic, copy) NSString *weekdayEndTime;

/// 周末是否启用
@property (nonatomic, assign) BOOL weekendActive;

/// 周末生效开始时间（格式：HH:mm，如 "10:00"）
@property (nonatomic, copy) NSString *weekendStartTime;

/// 周末生效结束时间（格式：HH:mm，如 "20:00"）
@property (nonatomic, copy) NSString *weekendEndTime;

/// 不生效时段开始时间（格式：HH:mm，如 "23:00"）
@property (nonatomic, copy) NSString *inactiveStartTime;

/// 不生效时段结束时间（格式：HH:mm，如 "06:00"）
@property (nonatomic, copy) NSString *inactiveEndTime;

/// 创建默认时段配置
+ (instancetype)defaultSchedule;

@end

/// 时段管理器
@interface ScheduleManager : NSObject

/// 全局时段配置
@property (nonatomic, strong) WIFISchedule *schedule;

/// 获取单例实例
+ (instancetype)sharedManager;

/// 判断当前时间是否在生效时段
/// @param scheduleType 时段类型
/// @return 是否在生效时段
- (BOOL)isCurrentlyActiveForScheduleType:(NSInteger)scheduleType;

/// 判断指定时间是否在生效时段
/// @param date 要检查的时间
/// @param scheduleType 时段类型
/// @return 是否在生效时段
- (BOOL)isDate:(NSDate *)date activeForScheduleType:(NSInteger)scheduleType;

/// 判断指定时间是否在禁止时段（深夜等）
/// @param date 要检查的时间
/// @return 是否在禁止时段
- (BOOL)isDateInInactivePeriod:(NSDate *)date;

/// 获取当前是星期几（1=周日，2=周一，...，7=周六）
- (NSInteger)currentWeekday;

/// 判断今天是否是工作日（周一到周五）
- (BOOL)isWeekday;

/// 判断今天是否是周末（周六周日）
- (BOOL)isWeekend;

/// 解析时间字符串为DateComponents
/// @param timeString 时间字符串（格式：HH:mm）
/// @param referenceDate 参考日期（用于创建完整的Date）
/// @return DateComponents（只包含小时和分钟）
- (NSDateComponents *)componentsFromTimeString:(NSString *)timeString referenceDate:(NSDate *)referenceDate;

/// 将Date转换为时间字符串
/// @param date 日期
/// @return 时间字符串（格式：HH:mm）
- (NSString *)timeStringFromDate:(NSDate *)date;

/// 更新时段配置
/// @param schedule 新的时段配置
- (void)updateSchedule:(WIFISchedule *)schedule;

/// 判断当前是否在禁止时段
/// @return 是否在禁止时段
- (BOOL)isInInactivePeriod;

@end

NS_ASSUME_NONNULL_END
