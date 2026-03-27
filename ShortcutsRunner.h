//
//  ShortcutsRunner.h
//  WiFiAutoShortcutLauncher
//
//  iOS 15.0 Jailbreak Plugin - Shortcuts Runner Module
//  Provides functionality to fetch and execute iOS Shortcuts
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ShortcutInfo
 * Represents a shortcut with its identifier, name, and icon
 */
@interface ShortcutInfo : NSObject

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong, nullable) UIImage *icon;

- (instancetype)initWithIdentifier:(NSString *)identifier name:(NSString *)name icon:(nullable UIImage *)icon;
+ (instancetype)shortcutWithIdentifier:(NSString *)identifier name:(NSString *)name icon:(nullable UIImage *)icon;

@end

/**
 * ShortcutsRunner
 * Main class for interacting with iOS Shortcuts app via Intents framework
 */
@interface ShortcutsRunner : NSObject

+ (instancetype)sharedRunner;

/**
 * Fetch all available shortcuts from the iOS Shortcuts app
 * @param completion Callback with array of ShortcutInfo objects
 */
- (void)fetchAvailableShortcuts:(void (^)(NSArray<ShortcutInfo *> *shortcuts))completion;

/**
 * Run a specific shortcut by its identifier
 * @param identifier The unique identifier of the shortcut
 * @param completion Callback with success status and optional error
 */
- (void)runShortcutWithIdentifier:(NSString *)identifier
                        completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/**
 * Show a local notification when shortcut execution fails
 * @param shortcutName The name of the shortcut that failed
 */
- (void)showFailureNotificationForShortcut:(NSString *)shortcutName;

/**
 * Request notification permission (required for failure notifications)
 * @param completion Callback with granted status
 */
- (void)requestNotificationPermission:(void (^)(BOOL granted))completion;

@end

NS_ASSUME_NONNULL_END
