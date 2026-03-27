//
//  WiFiWatcher.h
//  WiFiAutoShortcutLauncher
//
//  WiFi检测模块头文件
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WiFiWatcherDelegate <NSObject>

@required
/// WiFi连接成功回调
/// @param ssid WiFi名称
/// @param bssid WiFi路由器MAC地址
- (void)wifiDidConnectToSSID:(NSString *)ssid withBSSID:(NSString *)bssid;

/// WiFi断开回调
- (void)wifiDidDisconnect;

@optional
/// WiFi扫描失败回调
/// @param error 错误信息
- (void)wifiScanDidFailWithError:(NSError *)error;

@end

@interface WiFiWatcher : NSObject

/// 委托对象
@property (nonatomic, weak, nullable) id<WiFiWatcherDelegate> delegate;

/// 当前是否正在监控
@property (nonatomic, readonly) BOOL isWatching;

/// 当前连接的SSID
@property (nonatomic, readonly, nullable) NSString *currentSSID;

/// 当前连接的BSSID
@property (nonatomic, readonly, nullable) NSString *currentBSSID;

/// 监控的WiFi规则列表（SSID数组，不区分大小写比较）
@property (nonatomic, readonly) NSArray<NSString *> *watchedSSIDs;

/// 单例实例
+ (instancetype)sharedWatcher;

/// 初始化监控
/// @param ssids 需要监控的WiFi名称列表（不区分大小写）
/// @return YES表示初始化成功，NO表示失败（可能需要权限）
- (BOOL)startWatchingSSIDs:(NSArray<NSString *> *)ssids;

/// 停止监控
- (void)stopWatching;

/// 添加监控规则
/// @param ssid WiFi名称
- (void)addWatchedSSID:(NSString *)ssid;

/// 移除监控规则
/// @param ssid WiFi名称
- (void)removeWatchedSSID:(NSString *)ssid;

/// 清除所有监控规则
- (void)removeAllWatchedSSIDs;

@end

NS_ASSUME_NONNULL_END
