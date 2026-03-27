//
//  ShortcutsRunner.mm
//  WiFiAutoShortcutLauncher
//
//  iOS 15.0 Jailbreak Plugin - Shortcuts Runner Module Implementation
//

#import "ShortcutsRunner.h"
#import <objc/runtime.h>
#import <UserNotifications/UserNotifications.h>

// Intents framework headers for iOS 15
#define INTENTS_FRAMEWORK_PATH "/System/Library/Frameworks/Intents.framework"
#define INTENTSSUPPORT_FRAMEWORK_PATH "/System/Library/Frameworks/IntentsSupport.framework"

@implementation ShortcutInfo

- (instancetype)initWithIdentifier:(NSString *)identifier name:(NSString *)name icon:(UIImage *)icon {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _name = [name copy];
        _icon = icon;
    }
    return self;
}

+ (instancetype)shortcutWithIdentifier:(NSString *)identifier name:(NSString *)name icon:(UIImage *)icon {
    return [[self alloc] initWithIdentifier:identifier name:name icon:icon];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<ShortcutInfo: %@ (%@)>", self.name, self.identifier];
}

@end

@interface ShortcutsRunner () <UNUserNotificationCenterDelegate>

@property (nonatomic, strong) void (^pendingFetchCompletion)(NSArray<ShortcutInfo *> *);
@property (nonatomic, strong) void (^pendingRunCompletion)(BOOL, NSError *);
@property (nonatomic, assign) BOOL notificationPermissionGranted;

@end

@implementation ShortcutsRunner

#pragma mark - Singleton

+ (instancetype)sharedRunner {
    static ShortcutsRunner *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ShortcutsRunner alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _notificationPermissionGranted = NO;
        [self requestNotificationPermission:^(BOOL granted) {
            // Permission result handled
        }];
    }
    return self;
}

#pragma mark - Notification Permission

- (void)requestNotificationPermission:(void (^)(BOOL))completion {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;

    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        self.notificationPermissionGranted = granted;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(granted);
            }
        });
    }];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionNone);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

#pragma mark - Fetch Available Shortcuts

- (void)fetchAvailableShortcuts:(void (^)(NSArray<ShortcutInfo *> *))completion {
    self.pendingFetchCompletion = completion;

    // Use DLopen to load the IntentsSupport framework dynamically
    // This approach is common in jailbreak development to avoid direct linking
    void *intentsHandle = dlopen(INTENTSSUPPORT_FRAMEWORK_PATH, RTLD_LAZY);

    if (!intentsHandle) {
        // Fallback to Intents framework if IntentsSupport is not available
        intentsHandle = dlopen(INTENTS_FRAMEWORK_PATH, RTLD_LAZY);
    }

    if (intentsHandle) {
        [self fetchShortcutsViaIntentsFramework:completion];
        dlclose(intentsHandle);
    } else {
        // Fallback: Use private SpringBoard shortcuts API via DLopen
        [self fetchShortcutsViaSpringBoardBridge:completion];
    }
}

- (void)fetchShortcutsViaIntentsFramework:(void (^)(NSArray<ShortcutInfo *> *))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<ShortcutInfo *> *shortcuts = [NSMutableArray array];

        // Get the shared application list from Intents framework
        // INShortcutCenter provides access to user shortcuts
        Class INShortcutCenter = objc_getClass("INShortcutCenter");

        if (INShortcutCenter) {
            SEL sharedSelector = NSSelectorFromString(@"sharedShortcutCenter");
            if ([INShortcutCenter respondsToSelector:sharedSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                id sharedCenter = [INShortcutCenter performSelector:sharedSelector];
#pragma clang diagnostic pop

                if (sharedCenter) {
                    SEL allShortcutsSelector = NSSelectorFromString(@"allShortcuts");
                    if ([sharedCenter respondsToSelector:allShortcutsSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        NSArray *systemShortcuts = [sharedCenter performSelector:allShortcutsSelector];
#pragma clang diagnostic pop

                        for (id shortcut in systemShortcuts) {
                            ShortcutInfo *info = [self extractShortcutInfoFromShortcut:shortcut];
                            if (info) {
                                [shortcuts addObject:info];
                            }
                        }
                    }
                }
            }
        }

        // If no shortcuts found via INShortcutCenter, try alternative method
        if (shortcuts.count == 0) {
            [shortcuts addObjectsFromArray:[self fetchShortcutsViaAlternativeMethod]];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion([shortcuts copy]);
            }
        });
    });
}

- (ShortcutInfo *)extractShortcutInfoFromShortcut:(id)shortcut {
    if (!shortcut) return nil;

    NSString *identifier = nil;
    NSString *name = nil;
    UIImage *icon = nil;

    // Try to get identifier
    SEL identifierSelector = NSSelectorFromString(@"identifier");
    if ([shortcut respondsToSelector:identifierSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        identifier = [shortcut performSelector:identifierSelector];
#pragma clang diagnostic pop
    }

    // Try to get display name
    SEL displayNameSelector = NSSelectorFromString(@"displayName");
    if ([shortcut respondsToSelector:displayNameSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        name = [shortcut performSelector:displayNameSelector];
#pragma clang diagnostic pop
    }

    // Try to get icon
    SEL iconSelector = NSSelectorFromString(@"icon");
    if ([shortcut respondsToSelector:iconSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        icon = [shortcut performSelector:iconSelector];
#pragma clang diagnostic pop
    }

    if (identifier && name) {
        return [ShortcutInfo shortcutWithIdentifier:identifier name:name icon:icon];
    }

    return nil;
}

- (NSArray<ShortcutInfo *> *)fetchShortcutsViaAlternativeMethod {
    // Alternative method using INIntentSnippetViewController or other private APIs
    // This is a fallback mechanism for different iOS versions

    NSMutableArray<ShortcutInfo *> *shortcuts = [NSMutableArray array];

    // Try to load from Shortcuts app's private storage
    void *shortcutsAppHandle = dlopen("/Applications/Shortcuts.app/Shortcuts", RTLD_LAZY);

    if (shortcutsAppHandle) {
        // Access the shortcuts database or API
        // This is a placeholder for the actual implementation
        // which would involve parsing the shortcuts plist/database

        dlclose(shortcutsAppHandle);
    }

    // Try using INSearchForShortcutsIntent if available
    Class INSearchForShortcutsIntentClass = objc_getClass("INSearchForShortcutsIntent");

    if (INSearchForShortcutsIntentClass) {
        // Create and use the search intent
    }

    return [shortcuts copy];
}

- (void)fetchShortcutsViaSpringBoardBridge:(void (^)(NSArray<ShortcutInfo *> *))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<ShortcutInfo *> *shortcuts = [NSMutableArray array];

        // Use DLopen to load SpringBoard private framework
        // This allows bridging to shortcuts through SpringBoard
        void *sbHandle = dlopen("/System/Library/SpringBoard/SpringBoard Services/SpringBoardService.framework/SpringBoardService", RTLD_LAZY);

        if (sbHandle) {
            // Access SpringBoard's shortcut API
            // This is typically done through SBSServer or similar private APIs
            dlclose(sbHandle);
        }

        // Fallback: Try to read shortcuts from the app group shared container
        // Shortcuts are stored in app group container for sharing between apps
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths firstObject];

        // Navigate to Shortcuts app's stored shortcuts
        NSString *shortcutsPlistPath = [documentsPath stringByAppendingPathComponent:@"../Library/Application Support/com.apple.shortcuts"];

        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:shortcutsPlistPath]) {
            NSError *error = nil;
            NSArray *contents = [fm contentsOfDirectoryAtPath:shortcutsPlistPath error:&error];

            for (NSString *file in contents) {
                if ([file hasSuffix:@".shortcut"]) {
                    NSString *fullPath = [shortcutsPlistPath stringByAppendingPathComponent:file];
                    NSDictionary *shortcutDict = [NSDictionary dictionaryWithContentsOfFile:fullPath];

                    if (shortcutDict) {
                        NSString *identifier = shortcutDict[@"identifier"] ?: file;
                        NSString *name = shortcutDict[@"name"] ?: [file stringByDeletingPathExtension];
                        UIImage *icon = nil;

                        ShortcutInfo *info = [ShortcutInfo shortcutWithIdentifier:identifier
                                                                            name:name
                                                                            icon:icon];
                        [shortcuts addObject:info];
                    }
                }
            }
        }

        // Also try the shortcuts database in the shared app group
        NSString *appGroupPath = @"/var/mobile/Library/Application Support/com.apple.shortcuts";
        if ([fm fileExistsAtPath:appGroupPath]) {
            // Parse the shortcuts database
            NSString *dbPath = [appGroupPath stringByAppendingPathComponent:@"shortcuts.db"];
            if ([fm fileExistsAtPath:dbPath]) {
                // Database parsing would go here
                // SQLite3 would be used to read the shortcuts
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion([shortcuts copy]);
            }
        });
    });
}

#pragma mark - Run Shortcut

- (void)runShortcutWithIdentifier:(NSString *)identifier
                        completion:(void (^)(BOOL success, NSError *))completion {
    self.pendingRunCompletion = completion;

    if (!identifier || identifier.length == 0) {
        NSError *error = [NSError errorWithDomain:@"ShortcutsRunnerErrorDomain"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid shortcut identifier"}];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(NO, error);
            }
        });
        return;
    }

    // Use Intents framework to run the shortcut
    [self runShortcutViaIntentsFramework:identifier completion:completion];
}

- (void)runShortcutViaIntentsFramework:(NSString *)identifier
                            completion:(void (^)(BOOL success, NSError *))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Load IntentsSupport framework dynamically
        void *intentsHandle = dlopen(INTENTSSUPPORT_FRAMEWORK_PATH, RTLD_LAZY);

        if (!intentsHandle) {
            intentsHandle = dlopen(INTENTS_FRAMEWORK_PATH, RTLD_LAZY);
        }

        if (intentsHandle) {
            [self executeShortcutWithIntent:identifier];
            dlclose(intentsHandle);
        } else {
            // Fallback to SpringBoard bridge
            [self runShortcutViaSpringBoardBridge:identifier completion:completion];
        }
    });
}

- (void)executeShortcutWithIntent:(NSString *)identifier {
    // Create and execute INRunShortcutIntent
    // This is the primary method for running shortcuts on iOS 15

    Class INRunShortcutIntentClass = objc_getClass("INRunShortcutIntent");
    Class INShortcutIntentClass = objc_getClass("INShortcutIntent");
    Class INIntentResponseClass = objc_getClass("INIntentResponse");
    Class NSSelectorFromStringClass = objc_getClass("NSsetSelectorFromString");

    if (INRunShortcutIntentClass) {
        // Create the intent
        SEL initSelector = NSSelectorFromString(@"initWithShortcutIdentifier:");
        if ([INRunShortcutIntentClass instancesRespondToSelector:initSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id intent = [[INRunShortcutIntentClass alloc] performSelector:initSelector withObject:identifier];
#pragma clang diagnostic pop

            if (intent) {
                // Use INIntentCoordinator to execute the intent
                Class INIntentCoordinatorClass = objc_getClass("INIntentCoordinator");

                if (INIntentCoordinatorClass) {
                    SEL sharedCoordinatorSelector = NSSelectorFromString(@"sharedIntentCoordinator");
                    if ([INIntentCoordinatorClass respondsToSelector:sharedCoordinatorSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        id coordinator = [INIntentCoordinatorClass performSelector:sharedCoordinatorSelector];
#pragma clang diagnostic pop

                        if (coordinator) {
                            SEL coordinateSelector = NSSelectorFromString(@"coordinateIntent:completion:");
                            if ([coordinator respondsToSelector:coordinateSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                                [coordinator performSelector:coordinateSelector
                                                  withObject:intent
                                                  withObject:^(id response) {
                                    [self handleIntentResponse:response forIdentifier:identifier];
                                }];
#pragma clang diagnostic pop
                                return;
                            }
                        }
                    }
                }

                // Alternative: Use INIntentAgent or similar
                Class INIntentAgentClass = objc_getClass("INIntentAgent");
                if (INIntentAgentClass) {
                    SEL agentSelector = NSSelectorFromString(@"sharedAgent");
                    if ([INIntentAgentClass respondsToSelector:agentSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        id agent = [INIntentAgentClass performSelector:agentSelector];
#pragma clang diagnostic pop

                        if (agent) {
                            SEL executeSelector = NSSelectorFromString(@"executeIntent:completion:");
                            if ([agent respondsToSelector:executeSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                                [agent performSelector:executeSelector
                                            withObject:intent
                                            withObject:^(id response) {
                                    [self handleIntentResponse:response forIdentifier:identifier];
                                }];
#pragma clang diagnostic pop
                                return;
                            }
                        }
                    }
                }
            }
        }
    }

    // If we reach here, the primary method failed - try alternative
    [self runShortcutViaAlternativeMethod:identifier];
}

- (void)handleIntentResponse:(id)response forIdentifier:(NSString *)identifier {
    BOOL success = NO;
    NSError *error = nil;

    if (response) {
        // Check if response indicates success
        SEL codeSelector = NSSelectorFromString(@"code");
        if ([response respondsToSelector:codeSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSInteger code = [[response performSelector:codeSelector] integerValue];
#pragma clang diagnostic pop

            // INIntentResponseCodeSuccess = 0
            success = (code == 0);
        } else {
            // If no code, assume success if response exists
            success = YES;
        }

        if (!success) {
            // Extract error from response
            SEL errorSelector = NSSelectorFromString(@"error");
            if ([response respondsToSelector:errorSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                error = [response performSelector:errorSelector];
#pragma clang diagnostic pop
            }
        }
    } else {
        error = [NSError errorWithDomain:@"ShortcutsRunnerErrorDomain"
                                    code:-2
                                userInfo:@{NSLocalizedDescriptionKey: @"No response received from intent execution"}];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.pendingRunCompletion) {
            self.pendingRunCompletion(success, error);
            self.pendingRunCompletion = nil;
        }

        if (!success) {
            [self showFailureNotificationForShortcut:identifier];
        }
    });
}

- (void)runShortcutViaAlternativeMethod:(NSString *)identifier {
    // Alternative method using private APIs or direct shortcut execution

    // Try using the shortcuts runner service directly
    Class SSShortcutsRunnerClass = objc_getClass("SSShortcutsRunner");

    if (!SSShortcutsRunnerClass) {
        // Try loading from SpringBoard
        void *sbHandle = dlopen("/System/Library/SpringBoard/SpringBoard Services/SpringBoardService.framework/SpringBoardService", RTLD_LAZY);
        if (sbHandle) {
            SSShortcutsRunnerClass = objc_getClass("SSShortcutsRunner");
            dlclose(sbHandle);
        }
    }

    if (SSShortcutsRunnerClass) {
        SEL sharedRunnerSelector = NSSelectorFromString(@"sharedRunner");
        if ([SSShortcutsRunnerClass respondsToSelector:sharedRunnerSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            id runner = [SSShortcutsRunnerClass performSelector:sharedRunnerSelector];
#pragma clang diagnostic pop

            if (runner) {
                SEL runSelector = NSSelectorFromString(@"runShortcutWithIdentifier:completion:");
                if ([runner respondsToSelector:runSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [runner performSelector:runSelector
                                withObject:identifier
                                withObject:^(BOOL success, NSError *error) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        if (self.pendingRunCompletion) {
                                            self.pendingRunCompletion(success, error);
                                            self.pendingRunCompletion = nil;
                                        }

                                        if (!success) {
                                            [self showFailureNotificationForShortcut:identifier];
                                        }
                                    });
                                }];
#pragma clang diagnostic pop
                    return;
                }
            }
        }
    }

    // Final fallback: Use xpc call to shortcuts service
    [self runShortcutViaXPC:identifier];
}

- (void)runShortcutViaSpringBoardBridge:(NSString *)identifier
                             completion:(void (^)(BOOL success, NSError *))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Load SpringBoard framework to access shortcut execution
        void *sbHandle = dlopen("/System/Library/SpringBoard/SpringBoard Services/SpringBoardService.framework/SpringBoardService", RTLD_LAZY);

        if (sbHandle) {
            // Access SBSServer or similar private APIs for shortcut execution
            // This provides a bridge to execute shortcuts through SpringBoard

            dlclose(sbHandle);
        }

        // Try using the inter-process communication for shortcuts
        // Shortcuts app registers an XPC service
        [self runShortcutViaXPC:identifier];

        dispatch_async(dispatch_get_main_queue(), ^{
            // This will be called when XPC completes
        });
    });
}

- (void)runShortcutViaXPC:(NSString *)identifier {
    // XPC method for communicating with Shortcuts service
    // This is a low-level approach used when higher-level APIs are unavailable

    // Create the XPC connection
    // The shortcuts service typically registers as "com.apple.shortcuts.service"

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // xpc_connection_t connection = xpc_connection_create_mach_service(
        //     "com.apple.shortcuts.service",
        //     NULL,
        //     XPC_CONNECTION_MACH_SERVICE_PRIVILEGED
        // );

        // For jailbreak environment, we can also try:
        // - Direct socket communication
        // - CFMessagePort
        // - NSMachPort

        // Simulate completion for now - actual XPC implementation would go here
        // In a real implementation, this would use libxpc to send the shortcut
        // execution request to the Shortcuts service

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.pendingRunCompletion) {
                NSError *error = [NSError errorWithDomain:@"ShortcutsRunnerErrorDomain"
                                                     code:-3
                                                 userInfo:@{NSLocalizedDescriptionKey: @"XPC method not fully implemented - framework unavailable"}];
                self.pendingRunCompletion(NO, error);
                self.pendingRunCompletion = nil;
            }
        });
    });
}

#pragma mark - Failure Notification

- (void)showFailureNotificationForShortcut:(NSString *)shortcutName {
    if (!self.notificationPermissionGranted) {
        NSLog(@"[ShortcutsRunner] Notification permission not granted, cannot show failure notification");
        return;
    }

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Shortcut Execution Failed";
    content.body = [NSString stringWithFormat:@"The shortcut \"%@\" failed to execute.", shortcutName ?: @"Unknown"];
    content.sound = [UNNotificationSound defaultSound];
    content.badge = @1;

    // Add user info for potential handling
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (shortcutName) {
        userInfo[@"shortcutName"] = shortcutName;
    }
    userInfo[@"timestamp"] = @([[NSDate date] timeIntervalSince1970]);
    content.userInfo = [userInfo copy];

    // Create trigger (immediate delivery)
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger
                                                   triggerWithTimeInterval:0.1
                                                   repeats:NO];

    // Create unique identifier
    NSString *identifier = [NSString stringWithFormat:@"ShortcutFailure_%@_%f",
                           shortcutName ?: @"unknown",
                           [[NSDate date] timeIntervalSince1970]];

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                           content:content
                                                                           trigger:trigger];

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"[ShortcutsRunner] Failed to schedule failure notification: %@", error.localizedDescription);
        } else {
            NSLog(@"[ShortcutsRunner] Failure notification scheduled for shortcut: %@", shortcutName);
        }
    }];
}

@end
