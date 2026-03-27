//
//  WiFiWatcher.h
//  WiFiAutoShortcutLauncher
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WiFiWatcherDelegate <NSObject>
- (void)wifiDidConnectToSSID:(NSString *)ssid withBSSID:(NSString *)bssid;
- (void)wifiDidDisconnect;
@optional
- (void)wifiScanDidFailWithError:(NSError *)error;
@end

@interface WiFiWatcher : NSObject
+ (instancetype)sharedWatcher;
- (void)startWatching;
- (void)stopWatching;
- (void)startWatchingSSIDs:(NSArray<NSString *> *)ssids;
@property (nonatomic, assign) id<WiFiWatcherDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
