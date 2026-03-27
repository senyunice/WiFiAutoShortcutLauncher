//
//  ShortcutsRunner.mm
//  WiFiAutoShortcutLauncher
//

#import "ShortcutsRunner.h"

@implementation ShortcutsRunner

+ (instancetype)sharedRunner {
    static ShortcutsRunner *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[ShortcutsRunner alloc] init]; });
    return instance;
}

- (void)runShortcutWithIdentifier:(NSString *)identifier completion:(void (^)(BOOL, NSError * _Nullable))completion {
    (void)identifier;
    if (completion) completion(YES, nil);
}

- (void)showFailureNotificationForShortcut:(NSString *)shortcutName {
    (void)shortcutName;
}

@end
