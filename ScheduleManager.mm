//
//  ScheduleManager.mm
//  WiFiAutoShortcutLauncher
//

#import "ScheduleManager.h"

@implementation ScheduleManager

+ (instancetype)sharedManager {
    static ScheduleManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[ScheduleManager alloc] init]; });
    return instance;
}

- (BOOL)isInInactivePeriod {
    return NO;
}

- (BOOL)isCurrentlyActiveForScheduleType:(NSInteger)scheduleType {
    (void)scheduleType;
    return YES;
}

@end
