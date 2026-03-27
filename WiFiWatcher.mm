//
//  WiFiWatcher.mm
//  WiFiAutoShortcutLauncher
//
//  WiFi检测实现 - 使用NEHotspotHelper
//

#import "WiFiWatcher.h"
#import <NetworkExtension/NetworkExtension.h>
#import <objc/runtime.h>

// 定时检测间隔（秒）
static NSTimeInterval const kWiFiCheckInterval = 5.0;

@interface WiFiWatcher ()

@property (nonatomic, strong) NSMutableArray<NSString *> *mutableWatchedSSIDs;
@property (nonatomic, strong) NSTimer *checkTimer;
@property (nonatomic, assign) BOOL isWatching;
@property (nonatomic, copy) NSString *currentSSID;
@property (nonatomic, copy) NSString *currentBSSID;
@property (nonatomic, assign) BOOL hasRegisteredHelper;

@end

@implementation WiFiWatcher

#pragma mark - Singleton

+ (instancetype)sharedWatcher {
    static WiFiWatcher *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WiFiWatcher alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableWatchedSSIDs = [NSMutableArray array];
        _isWatching = NO;
        _hasRegisteredHelper = NO;
    }
    return self;
}

#pragma mark - Public Methods

- (NSArray<NSString *> *)watchedSSIDs {
    return [self.mutableWatchedSSIDs copy];
}

- (BOOL)startWatchingSSIDs:(NSArray<NSString *> *)ssids {
    if (ssids.count == 0) {
        return NO;
    }

    // 清除旧的监控规则
    [self.mutableWatchedSSIDs removeAllObjects];
    [self.mutableWatchedSSIDs addObjectsFromArray:ssids];

    // 注册NEHotspotHelper
    if (!self.hasRegisteredHelper) {
        [self registerHotspotHelper];
    }

    // 启动定时检测
    [self startTimer];

    self.isWatching = YES;

    // 立即执行一次检测
    [self checkCurrentWiFi];

    return YES;
}

- (void)stopWatching {
    [self stopTimer];
    self.isWatching = NO;
    self.currentSSID = nil;
    self.currentBSSID = nil;
}

- (void)addWatchedSSID:(NSString *)ssid {
    if (ssid.length == 0) {
        return;
    }

    NSString *uppercaseSSID = [ssid uppercaseString];
    for (NSString *existingSSID in self.mutableWatchedSSIDs) {
        if ([[existingSSID uppercaseString] isEqualToString:uppercaseSSID]) {
            return; // 已存在
        }
    }

    [self.mutableWatchedSSIDs addObject:ssid];

    // 如果正在监控，立即检测
    if (self.isWatching) {
        [self checkCurrentWiFi];
    }
}

- (void)removeWatchedSSID:(NSString *)ssid {
    if (ssid.length == 0) {
        return;
    }

    NSString *uppercaseSSID = [ssid uppercaseString];
    NSString *ssidToRemove = nil;

    for (NSString *existingSSID in self.mutableWatchedSSIDs) {
        if ([[existingSSID uppercaseString] isEqualToString:uppercaseSSID]) {
            ssidToRemove = existingSSID;
            break;
        }
    }

    if (ssidToRemove) {
        [self.mutableWatchedSSIDs removeObject:ssidToRemove];
    }
}

- (void)removeAllWatchedSSIDs {
    [self.mutableWatchedSSIDs removeAllObjects];
}

#pragma mark - Private Methods

- (void)registerHotspotHelper {
    // NEHotspotHelper注册
    // 需要com.apple.developer.networking.HotspotHelper entitlements
    NEHotspotHelper *helper = [NEHotspotHelper sharedInstance];

    if (helper) {
        // 设置委托
        objc_setAssociatedObject(helper,
                                 @selector(delegate),
                                 self,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        // 尝试获取热点列表
        [helper getConfiguredHotspotListWithSSIDMatch:@[]];
    }
}

- (void)startTimer {
    [self stopTimer];

    self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:kWiFiCheckInterval
                                                      target:self
                                                    selector:@selector(checkCurrentWiFi)
                                                    userInfo:nil
                                                     repeats:YES];
    // 确保持续运行
    [[NSRunLoop mainRunLoop] addTimer:self.checkTimer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer {
    if (self.checkTimer) {
        [self.checkTimer invalidate];
        self.checkTimer = nil;
    }
}

- (void)checkCurrentWiFi {
    // 使用NEHotspotHelper获取当前WiFi信息
    [self fetchCurrentWiFiInfoWithCompletion:^(NSString *ssid, NSString *bssid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleWiFiResult:ssid bssid:bssid];
        });
    }];
}

- (void)fetchCurrentWiFiInfoWithCompletion:(void (^)(NSString *ssid, NSString *bssid))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *ssid = nil;
        NSString *bssid = nil;

        // 方式1: 通过NEHotspotHelper获取
        NEHotspotHelper *helper = [NEHotspotHelper sharedInstance];
        if (helper) {
            NSArray *hotspotNetworkList = [helper hotspotNetworkList];
            for (NEHotspotNetwork *network in hotspotNetworkList) {
                // 获取当前连接的WiFi
                if (network.isCurrent) {
                    ssid = network.ssid;
                    bssid = network.bssid;
                    break;
                }
            }
        }

        // 方式2: 通过SystemConfiguration获取（备选方案）
        if (!ssid) {
            NSString *wifiAddress = [self getWiFiAddress];
            if (wifiAddress) {
                // 从系统配置获取SSID
                CFArrayRef interfaces = CNCopySupportedInterfaces();
                if (interfaces) {
                    for (int i = 0; i < CFArrayGetCount(interfaces); i++) {
                        const char *interfaceName = CFArrayGetValueAtIndex(interfaces, i);
                        NSString *interface = [NSString stringWithUTF8String:interfaceName];

                        CFDictionaryRef networkInfo = CNCopyCurrentNetworkInfo((__bridge CFStringRef)interface);
                        if (networkInfo) {
                            ssid = (__bridge_transfer NSString *)CFDictionaryGetValue(networkInfo, kCNNetworkInfoKeySSID);
                            bssid = (__bridge_transfer NSString *)CFDictionaryGetValue(networkInfo, kCNNetworkInfoKeyBSSID);
                            CFRelease(networkInfo);

                            if (ssid) {
                                ssid = [ssid copy];
                            }
                            if (bssid) {
                                bssid = [bssid copy];
                            }
                            break;
                        }
                    }
                    CFRelease(interfaces);
                }
            }
        }

        completion(ssid, bssid);
    });
}

- (NSString *)getWiFiAddress {
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;

    // 获取网络接口列表
    if (getifaddrs(&interfaces) == 0) {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                // 检查是否是WiFi接口 (en0通常是WiFi)
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    freeifaddrs(interfaces);
                    return [NSString stringWithUTF8String:
                            inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return nil;
}

- (void)handleWiFiResult:(NSString *)ssid bssid:(NSString *)bssid {
    NSString *previousSSID = self.currentSSID;

    if (ssid.length > 0) {
        self.currentSSID = ssid;
        self.currentBSSID = bssid ?: @"";
    } else {
        self.currentSSID = nil;
        self.currentBSSID = nil;
    }

    // 判断是否有变化
    BOOL ssidChanged = (previousSSID != nil && self.currentSSID == nil) ||
                       (previousSSID == nil && self.currentSSID != nil) ||
                       (previousSSID != nil && self.currentSSID != nil &&
                        ![previousSSID isEqualToString:self.currentSSID]);

    if (ssidChanged) {
        if (self.currentSSID.length > 0) {
            // WiFi连接上了
            [self notifyWiFiConnected:ssid withBSSID:bssid];
        } else {
            // WiFi断开了
            [self notifyWiFiDisconnected];
        }
    } else if (self.currentSSID.length > 0) {
        // 状态没变，但可能需要检查是否在监控列表中
        // （用于处理应用启动时已有WiFi连接的情况）
        if (![self isSSIDWatched:ssid] && previousSSID == nil) {
            // 如果当前SSID不在监控列表，且之前没有连接
            // 不触发回调
        }
    }
}

- (BOOL)isSSIDWatched:(NSString *)ssid {
    if (ssid.length == 0 || self.mutableWatchedSSIDs.count == 0) {
        return NO;
    }

    NSString *uppercaseSSID = [ssid uppercaseString];

    for (NSString *watchedSSID in self.mutableWatchedSSIDs) {
        if ([[watchedSSID uppercaseString] isEqualToString:uppercaseSSID]) {
            return YES;
        }
    }

    return NO;
}

- (void)notifyWiFiConnected:(NSString *)ssid withBSSID:(NSString *)bssid {
    if ([self.delegate respondsToSelector:@selector(wifiDidConnectToSSID:withBSSID:)]) {
        [self.delegate wifiDidConnectToSSID:ssid withBSSID:bssid ?: @""];
    }
}

- (void)notifyWiFiDisconnected {
    if ([self.delegate respondsToSelector:@selector(wifiDidDisconnect)]) {
        [self.delegate wifiDidDisconnect];
    }
}

#pragma mark - Cleanup

- (void)dealloc {
    [self stopWatching];
}

@end
