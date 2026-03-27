#import "WiFiWatcher.h"
#import "ShortcutsRunner.h"
#import "ConfigManager.h"
#import "ScheduleManager.h"
#import "WIFIRule.h"

@interface WiFiAutoShortcutLauncherController : NSObject <WiFiWatcherDelegate>
@property (nonatomic, strong) NSMutableSet<NSString *> *processedSSIDs;
@property (nonatomic, assign) BOOL isProcessing;
@end

@implementation WiFiAutoShortcutLauncherController

+ (instancetype)sharedInstance {
    static WiFiAutoShortcutLauncherController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WiFiAutoShortcutLauncherController alloc] init];
        sharedInstance.processedSSIDs = [NSMutableSet set];
        sharedInstance.isProcessing = NO;
    });
    return sharedInstance;
}

- (void)start {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"WiFiAutoShortcutLauncherEnabled"]) {
        NSLog(@"[WiFiAutoShortcutLauncher] Plugin is disabled");
        return;
    }

    [WiFiWatcher sharedWatcher].delegate = self;
    [[WiFiWatcher sharedWatcher] startWatching];

    NSArray<WIFIRule *> *rules = [[ConfigManager sharedManager] enabledRules];
    NSMutableArray<NSString *> *ssids = [NSMutableArray array];
    for (WIFIRule *rule in rules) {
        [ssids addObject:rule.ssid];
    }
    [[WiFiWatcher sharedWatcher] startWatchingSSIDs:ssids];

    NSLog(@"[WiFiAutoShortcutLauncher] Started with %lu rules", (unsigned long)rules.count);
}

- (void)stop {
    [[WiFiWatcher sharedWatcher] stopWatching];
}

#pragma mark - WiFiWatcherDelegate

- (void)wifiDidConnectToSSID:(NSString *)ssid withBSSID:(NSString *)bssid {
    if (self.isProcessing) {
        NSLog(@"[WiFiAutoShortcutLauncher] Already processing, skipping");
        return;
    }

    // Check if in inactive period
    if ([[ScheduleManager sharedManager] isInInactivePeriod]) {
        NSLog(@"[WiFiAutoShortcutLauncher] In inactive period, ignoring %@", ssid);
        return;
    }

    // Check if this SSID was recently processed (debounce)
    if ([self.processedSSIDs containsObject:ssid]) {
        NSLog(@"[WiFiAutoShortcutLauncher] %@ already processed recently", ssid);
        return;
    }

    // Find matching rule
    WIFIRule *rule = [[ConfigManager sharedManager] ruleForSSID:ssid];
    if (!rule) {
        NSLog(@"[WiFiAutoShortcutLauncher] No rule found for %@", ssid);
        return;
    }

    if (!rule.isEnabled) {
        NSLog(@"[WiFiAutoShortcutLauncher] Rule for %@ is disabled", ssid);
        return;
    }

    // Check schedule
    if (![[ScheduleManager sharedManager] isCurrentlyActiveForScheduleType:rule.scheduleType]) {
        NSLog(@"[WiFiAutoShortcutLauncher] Rule for %@ is not in active schedule", ssid);
        return;
    }

    self.isProcessing = YES;
    [self.processedSSIDs addObject:ssid];

    NSLog(@"[WiFiAutoShortcutLauncher] Triggering shortcut '%@' for WiFi '%@'", rule.shortcutName, ssid);

    [[ShortcutsRunner sharedRunner] runShortcutWithIdentifier:rule.shortcutIdentifier
                                                  completion:^(BOOL success, NSError *error) {
        self.isProcessing = NO;

        if (!success) {
            NSLog(@"[WiFiAutoShortcutLauncher] Shortcut failed: %@", error.localizedDescription);
            [[ShortcutsRunner sharedRunner] showFailureNotificationForShortcut:rule.shortcutName];
        } else {
            NSLog(@"[WiFiAutoShortcutLauncher] Shortcut '%@' executed successfully", rule.shortcutName);
        }
    }];

    // Clear processed SSID after 60 seconds to allow re-triggering
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.processedSSIDs removeObject:ssid];
    });
}

- (void)wifiDidDisconnect {
    NSLog(@"[WiFiAutoShortcutLauncher] WiFi disconnected");
}

- (void)wifiScanDidFailWithError:(NSError *)error {
    NSLog(@"[WiFiAutoShortcutLauncher] WiFi scan failed: %@", error.localizedDescription);
}

@end

// Hook into SpringBoard to start service
__attribute__((constructor))
static void initialize() {
    NSLog(@"[WiFiAutoShortcutLauncher] Initializing...");

    // Small delay to ensure system is ready
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[WiFiAutoShortcutLauncherController sharedInstance] start];
    });
}
