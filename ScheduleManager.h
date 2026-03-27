//
//  ScheduleManager.h
//  WiFiAutoShortcutLauncher
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScheduleManager : NSObject
+ (instancetype)sharedManager;
- (BOOL)isInInactivePeriod;
- (BOOL)isCurrentlyActiveForScheduleType:(NSInteger)scheduleType;
@end

NS_ASSUME_NONNULL_END
