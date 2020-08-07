//
//  PTBLE.h
//  PublicHouse
//
//  Created by Jinbo Lu on 2018/7/11.
//  Copyright © 2018年 HangZhouSciener. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTLock.h"
#import "LockModel.h"


typedef NS_ENUM(NSInteger,BLEConnectStatus) {
    BLEConnectStatusPowerOff = 0,
    BLEConnectStatusTimeout,
    BLEConnectStatusBusy,
    BLEConnectStatusUnauthorized,
    BLEConnectStatusSuccess
};

typedef NS_ENUM(NSInteger,LockAccess) {
    LockAccessIC = 1,
    LockAccessFingerprint,
};


typedef NS_ENUM(NSInteger,LockAccessOpration) {
    LockAccessOprationAdd = 0,
    LockAccessOprationClear,
    LockAccessOprationDelete,
    LockAccessOprationModif,
    LockAccessOprationGet,
};

typedef NS_ENUM(NSInteger,BLECommand) {
    BLECommandScan = 1,
    BLECommandScanMac,
    BLECommandConnect,
    BLECommandUnlock,
    BLECommandGetRecord,//锁内存存储的记录
    BLECommandSetTime,
    BLECommandGetTime,
    BLECommandAddLock,
    
    BLECommandSetNB,
    
    BLECommandAccessoryAdd,//添加IC 指纹
    BLECommandAccessDelete,
    BLECommandAccessClear,
    BLECommandAccessModify,
    
    BLECommandRecoverPassword,//恢复密码
    BLECommandResetLock,//恢复出厂设置
    
    BLECommandGetSpecialValue,//读取特征值
    BLECommandGetSystem,//系统的固件版本
    BLECommandGetStorageData,//锁内存储的密码、ic、指纹
    
    BLECommandActiveUpgrade,//锁激活升级
    BLECommandUpgradeProgress,//锁升级进度
    BLECommandUpgrade,//锁升级
};




static NSString* PTBLE_DISABLE = @"请打开蓝牙";

static NSString* PTBLE_NOTIFICATION_UPGRADE_ERROR = @"PTBLE_NOTIFICATION_UPGRADE_ERROR";
static NSString* PTBLE_NOTIFICATION_UNLOCK = @"PTBLE_NOTIFICATION_UNLOCK";
static NSString* PTBLE_NOTIFICATION_STATE = @"PTBLE_NOTIFICATION_STATE";

typedef void(^BLECompletion)(BOOL success,id info);

@interface PTBLE : NSObject
+ (instancetype)shareInstance;
@property (nonatomic, strong) NSString *uid;//当前操作的用户ID
@property (nonatomic, strong)  LockModel *currentKey;
@property (nonatomic, strong) NSArray *currentKeyArray;
@property (nonatomic, assign) BOOL touchUnlock;
@property (nonatomic, assign,readonly) BOOL bleEnable;
@property (nonatomic, assign,readonly) BOOL isBLEConnected;


/** 搜索周边搜索蓝牙 */
- (void)scan;
/** 搜索周边所有的蓝牙 并返回*/
- (void)scan:(BLECompletion)completion;
/** 搜索某个蓝牙目标 */
- (void)scanMac:(NSString *)mac completion:(BLECompletion)completion;
/** 停止搜索蓝牙 */
- (void)stopScan;
/** 连接蓝牙 */
- (void)connectPeripheral:(CBPeripheral *)peripheral completion:(BLECompletion)completion;
/** 连接周围蓝牙 （需要先开启搜索蓝牙） */
- (void)connectMac:(NSString *)mac completion:(BLECompletion)completion;
/** 主动断开蓝牙连接 */
- (void)disconnect;
/** 添加锁 */
- (void)addLock:(ScanModel *)addModel completion:(BLECompletion)completion;
/** 设置锁的NB地址 和 端口*/
- (void)setNBServerPortNumber:(NSString *)portNumber serverAddress:(NSString *)serverAddress key:(LockModel *)key completion:(BLECompletion)completion;
/** 开锁 */
- (void)unlockKey:(LockModel *)key completion:(BLECompletion)completion;
/** 获取蓝牙的操作记录 */
- (void)getUnlockRecordKey:(LockModel *)key completion:(BLECompletion)completion;
/** 设置锁的时间   timeValue == 0（获取服务器时间）， timeValue != 0（设置该时间） */
- (void)setLockTimeValue:(long long)timeValue key:(LockModel *)key completion:(BLECompletion)completion;
/** 获取锁里面的时间 */
- (void)getLockTimeValueKey:(LockModel *)key completion:(BLECompletion)completion;
/** 获取锁的特征值 */
- (void)getLockSpecialValue:(LockModel *)key completion:(BLECompletion)completion;
/** 获取锁的固件版本号 */
- (void)getLockSystemLockKey:(NSString*)lockkey aesKey:(NSString*)aesKey completion:(BLECompletion)completion;
/** 获取锁里面存储的密码 */
- (void)getLockPasswordListKey:(LockModel *)key completion:(BLECompletion)completion;
/** 获取锁里面的密码方案 */
- (void)getLockPasswordInfoKey:(LockModel *)key completion:(BLECompletion)completion;
/** 恢复出厂设置*/
- (void)resetLockKey:(LockModel*)key completion:(BLECompletion)completion;

/** 恢复锁的密码*/
- (void)recoverKeyboardPassword:(NSString *)password
                   passwordType:(NSInteger)passwordType
                      cycleType:(NSInteger)cycleType
                      startDate:(long long)startDate
                        endDate:(long long)endDate
                            key:(LockModel *)key
                     completion:(BLECompletion)completion;

/**  添加  修改 删除  恢复  IC 指纹 */
//- (void)access:(LockAccess)access opration:(OprationType)opration accessNumber:(NSString *)accessNumber adminPS:(NSString *)adminPS lockKey:(NSString *)lockKey aeskey:(NSString *)aeskey unlockFlag:(int)unlockFlag startDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(BLECompletion)completion;
/*********************************   锁升级    *********************************/
//- (void)activeUpgradeKey:(LockModel *)key completion:(BLECompletion)completion;
//- (void)upgradeFile:(NSString *)file peripheral:(CBPeripheral*)peripheral progress:(BLECompletion)progress completion:(BLECompletion)completion;
//- (BOOL)stopUpgrade;
//- (void)restartUpgrade;
//- (void)pauseUpgrade;
@end
