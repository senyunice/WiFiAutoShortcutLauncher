//
//  WiFiWatcher.mm
//  WiFiAutoShortcutLauncher
//

#import "WiFiWatcher.h"

@implementation WiFiWatcher

+ (instancetype)sharedWatcher {
    static WiFiWatcher *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[WiFiWatcher alloc] init]; });
    return instance;
}

- (void)startWatching {
    // Stub - real implementation requires iOS device
}

- (void)stopWatching {
    // Stub - real implementation requires iOS device
}

- (void)startWatchingSSIDs:(NSArray<NSString *> *)ssids {
    (void)ssids;
}

@end
