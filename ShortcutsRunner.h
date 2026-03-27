//
//  ShortcutsRunner.h
//  WiFiAutoShortcutLauncher
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShortcutsRunner : NSObject
+ (instancetype)sharedRunner;
- (void)runShortcutWithIdentifier:(NSString *)identifier completion:(void (^)(BOOL success, NSError * _Nullable error))completion;
- (void)showFailureNotificationForShortcut:(NSString *)shortcutName;
@end

NS_ASSUME_NONNULL_END
