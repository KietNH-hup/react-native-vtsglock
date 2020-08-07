//
//  PTBLE.m
//  PublicHouse
//
//  Created by Jinbo Lu on 2018/7/11.
//  Copyright © 2018年 HangZhouSciener. All rights reserved.
//

#import "PTBLE.h"
#import <AVFoundation/AVFoundation.h>
#import <libkern/OSAtomic.h>

@interface NSArray (Helper)
- (id)objectAtIndexSafe:(NSInteger)index;
@end
@interface NSMutableDictionary (Helper)
- (void)setObjectSafe:(id)object forKey:(id)key;
@end

@interface PTBLE ()<TTSDKDelegate>
@property (nonatomic, strong) TTLock *ttlock;
@property (nonatomic, strong) NSMutableDictionary *commandDict;
@property (nonatomic, strong) NSNumber *uniqueid;
@property (nonatomic, strong) CBPeripheral *currentPeripheral;

@property (nonatomic, strong) NSArray *connectFailDescribeArray;
@property (atomic, strong) NSMutableArray *addLockModelArray;

//@property (nonatomic, strong) DFUServiceController *dfuServiceController;
@property (nonatomic, assign) NSInteger dfuMaxRepeat;//重复升级
@property (nonatomic, strong) NSString *scanMac;
@property (nonatomic, assign) BOOL isScanDFUTimeOut;//搜索附近处于待升级状态
@property (nonatomic, strong) NSMutableArray *scanDFUArray;//搜索附近处于待升级状态的老锁
@end



@implementation PTBLE

+ (instancetype)shareInstance {
    static PTBLE* s_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [[PTBLE alloc] init];
    });
    return s_instance;
}

- (instancetype)init{
    if (self = [super init]) {
        _commandDict = @{}.mutableCopy;
        _connectFailDescribeArray = @[@"Bluetooth has been turn off,please turn on bluetooth",
                                 @"Bluetooth connect timeout",
                                 @"Bluetooth is busying,try later again",
                                 @"Bluetooth is not authorized",
                                 @"Bluetooth connect success",
                                 @""];
        _ttlock = [[TTLock alloc] initWithDelegate:self];
        [_ttlock setupBlueTooth];
    }
    return self;
}

- (BOOL)bleEnable{
    return _ttlock.state == TTManagerStatePoweredOn;
}

- (BOOL)isBLEConnected{
    return _currentPeripheral != nil;
}


- (void)scan{
    [_ttlock startBTDeviceScan:false];
}

- (void)scan:(BLECompletion)completion{
    _commandDict[@(BLECommandScan)] = completion;
    [_commandDict removeObjectForKey:@(BLECommandScanMac)];
    [_ttlock startBTDeviceScan:false];
    if (completion) {
        _addLockModelArray = @[].mutableCopy;
    }
}



- (void)scanMac:(NSString *)mac completion:(BLECompletion)completion{
    _commandDict[@(BLECommandScanMac)] = completion;
    _scanMac = mac;
    _scanDFUArray = @[].mutableCopy;
    _isScanDFUTimeOut = false;
    [_ttlock scanAllBluetoothDeviceNearby:true];
    [self performSelector:@selector(scanDFUTimeOut) withObject:nil afterDelay:6];
}

- (void)stopScan {
    [_ttlock stopBTDeviceScan];
    [_commandDict removeObjectForKey:@(BLECommandScan)];
    [_commandDict removeObjectForKey:@(BLECommandScanMac)];
    _scanDFUArray = nil;
    _addLockModelArray = nil;
}

- (void)connectMac:(NSString *)mac completion:(BLECompletion)completion {
    [self connectTarget:mac completion:completion];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral completion:(BLECompletion)completion{
    [self connectTarget:peripheral completion:completion];
}

- (void)connectTarget:(id)target completion:(BLECompletion)completion{
    if (_currentPeripheral != nil && completion) {
        dispatch_main_async(^{
            completion(false,[self.connectFailDescribeArray objectAtIndexSafe:BLEConnectStatusBusy]);
        });
        return;
    }
    
    if (_ttlock.state != TTManagerStatePoweredOn) {
        dispatch_main_async(^{
            if (self.ttlock.state == TTManagerStatePoweredOff) {
                completion(false,[self.connectFailDescribeArray objectAtIndexSafe:BLEConnectStatusPowerOff]);
            }else if (self.ttlock.state == TTManagerStateUnauthorized) {
                completion(false,[self.connectFailDescribeArray objectAtIndexSafe:BLEConnectStatusUnauthorized]);
            }
        });
        return;
    }
    _commandDict[@(BLECommandConnect)] = completion;
    NSLog(@"尝试连接:%@",target);
    if ([target isKindOfClass:[CBPeripheral class]]) {
        [_ttlock connect:target];
    }else if ([target isKindOfClass:[NSString class]]) {
        [_ttlock connectPeripheralWithLockMac:target];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(connectTimeOut:) withObject:target afterDelay:15];
}

- (void)disconnect {
    if (_currentPeripheral != nil) {
        [_ttlock disconnect:_currentPeripheral];
    }
}

- (void)addLock:(ScanModel *)addModel completion:(BLECompletion)completion {
    _commandDict[@(BLECommandAddLock)] = completion;
    NSDictionary *dict = @{@"lockMac":addModel.lockMac,
                           @"protocolType":addModel.protocolType,
                           @"protocolVersion":addModel.protocolVersion
                           };
    [_ttlock lockInitializeWithInfoDic:dict];
}

- (void)setNBServerPortNumber:(NSString *)portNumber serverAddress:(NSString *)serverAddress key:(LockModel *)key completion:(BLECompletion)completion{
    _commandDict[@(BLECommandSetNB)] = completion;
    _currentKey = key;
    [_ttlock setNBServerWithPortNumber:portNumber serverAddress:serverAddress adminPS:key.adminPwd lockKey:key.lockKey aesKey:key.aesKeyStr unlockFlag:key.lockFlagPos.intValue];
}

- (void)unlockKey:(LockModel *)key completion:(BLECompletion)completion {
    _commandDict[@(BLECommandUnlock)] = completion;
    _currentKey = key;
    
    NSDate *startDate = nil;
    NSDate *endDate = nil;
    if (key.startDate.length && key.endDate.length) {
        startDate = [NSDate dateWithTimeIntervalSince1970:key.startDate.longLongValue / 1000];
        endDate = [NSDate dateWithTimeIntervalSince1970:key.endDate.longLongValue / 1000];
    }
    _uniqueid = @([NSDate date].timeIntervalSince1970);
    [_ttlock unlockByUser_lockKey:key.lockKey aesKey:key.aesKeyStr startDate:startDate endDate:endDate version:key.version unlockFlag:key.lockFlagPos.intValue uniqueid:_uniqueid timezoneRawOffset:-1];
}


- (void)connectTimeOut:(NSString *)mac {
    BLECompletion completion = _commandDict[@(BLECommandConnect)];
    if (completion) {
        [_ttlock cancelConnectPeripheralWithLockMac:mac];
        [_commandDict removeObjectForKey:@(BLECommandConnect)];
        completion(false,[_connectFailDescribeArray objectAtIndexSafe:BLEConnectStatusTimeout]);
    }
}

- (void)scanDFUTimeOut {
    _isScanDFUTimeOut = true;
    NSLog(@"开始尝试遍历附近已经进入升级状态的锁");
}


- (void)getUnlockRecordKey:(LockModel *)key completion:(BLECompletion)completion {
    _commandDict[@(BLECommandGetRecord)] = completion;
    _currentKey = key;
    [_ttlock getOperateLog_aesKey:key.aesKeyStr version:key.version unlockFlag:key.lockFlagPos.intValue timezoneRawOffset:-1];
}

- (void)setLockTimeValue:(long long)timeValue key:(LockModel *)key completion:(BLECompletion)completion {
    if (timeValue > 0) {
        _commandDict[@(BLECommandSetTime)] = completion;
        [_ttlock setLockTime_lockKey:key.lockKey aesKey:key.aesKeyStr version:key.version unlockFlag:key.lockFlagPos.intValue referenceTime:[NSDate dateWithTimeIntervalSince1970:timeValue/1000] timezoneRawOffset:-1];
    }else{
      
    }
}

- (void)getLockTimeValueKey:(LockModel *)key completion:(BLECompletion)completion{
    _commandDict[@(BLECommandGetTime)] = completion;
    _currentKey = key;
    [_ttlock getLockTime_aesKey:key.aesKeyStr version:key.version unlockFlag:key.lockFlagPos.intValue timezoneRawOffset:-1];
}

- (void)access:(LockAccess)access opration:(OprationType)opration accessNumber:(NSString *)accessNumber adminPS:(NSString *)adminPS lockKey:(NSString *)lockKey aeskey:(NSString *)aeskey unlockFlag:(int)unlockFlag startDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(BLECompletion)completion {
    
    if (opration == OprationTypeAdd || opration == OprationTypeRecover) {
        _commandDict[@(BLECommandAccessoryAdd)] = completion;
    }else if (opration == OprationTypeClear){
        _commandDict[@(BLECommandAccessClear)] = completion;
    }else if (opration == OprationTypeDelete){
        _commandDict[@(BLECommandAccessDelete)] = completion;
    }else if (opration == OprationTypeModify){
        _commandDict[@(BLECommandAccessModify)] = completion;
    }else if (opration == OprationTypeQuery){
        _commandDict[@(BLECommandGetStorageData)] = completion;
    }
    
    if (access == LockAccessIC) {
        NSLog(@"设置 IC 起始时间:%@  结束时间:%@ ",startDate,endDate);
        [_ttlock operate_type:opration adminPS:adminPS lockKey:lockKey aesKey:aeskey ICNumber:accessNumber startDate:startDate endDate:endDate unlockFlag:unlockFlag timezoneRawOffset:-1];
    }else if (access == LockAccessFingerprint){
        [_ttlock operateFingerprint_type:opration adminPS:adminPS lockKey:lockKey aesKey:aeskey FingerprintNumber:accessNumber startDate:startDate endDate:endDate unlockFlag:unlockFlag timezoneRawOffset:-1];
    }
}

- (void)getLockSpecialValue:(LockModel *)key completion:(BLECompletion)completion{
    _currentKey = key;
    _commandDict[@(BLECommandGetSpecialValue)] = completion;
    [_ttlock getDeviceCharacteristic_lockKey:key.lockKey aesKey:key.aesKeyStr];
}

- (void)getLockSystemLockKey:(NSString*)lockkey aesKey:(NSString*)aesKey completion:(BLECompletion)completion{
    _commandDict[@(BLECommandGetSystem)] = completion;
    [_ttlock getDeviceInfo_lockKey:lockkey aesKey:aesKey];
}

- (void)getLockPasswordListKey:(LockModel *)key completion:(BLECompletion)completion{
    _currentKey = key;
    _commandDict[@(BLECommandGetStorageData)] = completion;
    [_ttlock getKeyboardPasswordList_adminPS:key.adminPwd lockKey:key.lockKey aesKey:key.aesKeyStr unlockFlag:key.lockFlagPos.intValue timezoneRawOffset:-1];
}

- (void)getLockPasswordInfoKey:(LockModel *)key completion:(BLECompletion)completion{
    _currentKey = key;
    _commandDict[@(BLECommandGetStorageData)] = completion;
    [_ttlock getPasswordData_lockKey:key.lockKey aesKey:key.aesKeyStr unlockFlag:key.lockFlagPos.intValue timezoneRawOffset:-1];
}

- (void)resetLockKey:(LockModel*)key completion:(BLECompletion)completion{
    _commandDict[@(BLECommandResetLock)] = completion;
    _currentKey = key;
    [_ttlock resetLock_adminPS:key.adminPwd lockKey:key.lockKey aesKey:key.aesKeyStr version:key.version unlockFlag:key.lockFlagPos.intValue];
}

- (void)recoverKeyboardPassword:(NSString *)password
                   passwordType:(NSInteger)passwordType
                      cycleType:(NSInteger)cycleType
                      startDate:(long long)startDate
                        endDate:(long long)endDate
                                key:(LockModel *)key
                         completion:(BLECompletion)completion{
    
    _commandDict[@(BLECommandRecoverPassword)] = completion;
    _currentKey = key;
    NSDate *start_date = nil;
    NSDate *end_date = nil;
    if (startDate > 0 && endDate > 0) {
        start_date = [NSDate dateWithTimeIntervalSince1970:startDate/1000];
        end_date = [NSDate dateWithTimeIntervalSince1970:endDate/1000];
    }
    [_ttlock recoverKeyboardPassword_passwordType:passwordType
                                                             cycleType:cycleType
                                                           newPassword:password
                                                           oldPassword:password
                                                             startDate:start_date
                                                               endDate:end_date
                                                               adminPS:key.adminPwd
                                                               lockKey:key.lockKey
                                                                aesKey:key.aesKeyStr
                                                            unlockFlag:key.lockFlagPos.intValue
                                                     timezoneRawOffset:-1];
}

/*********************************   锁升级    *********************************/
- (void)activeUpgradeKey:(LockModel *)key completion:(BLECompletion)completion {
    _commandDict[@(BLECommandActiveUpgrade)] = completion;
    _currentKey = key;
    [_ttlock upgradeFirmware_adminPS:key.adminPwd lockKey:key.lockKey aesKey:key.aesKeyStr unlockFlag:key.lockFlagPos.intValue];
}



#pragma mark - TTSDKDelegate

- (void)TTManagerDidUpdateState:(TTManagerState)state {
    if (state == TTManagerStatePoweredOff) {
        _currentKey = nil;
        _currentPeripheral = nil;
        [_addLockModelArray removeAllObjects];
        [_commandDict enumerateKeysAndObjectsUsingBlock:^(NSNumber*  _Nonnull command, BLECompletion  _Nonnull completion, BOOL * _Nonnull stop) {
            NSError *error = [NSError errorWithDomain:@"PTBLE" code:0x123f userInfo:@{NSLocalizedDescriptionKey: @"蓝牙已关闭，请重启蓝牙"}];
            dispatch_main_async(^{
                completion(false,error);
            });
            
        }];
        [_commandDict removeAllObjects];
    }
    dispatch_main_async(^{
//        NOTIF_POST(PTBLE_NOTIFICATION_STATE, @{@"state":@(state)});
    });
}

- (void)TTError:(TTError)error command:(int)command errorMsg:(NSString *)errorMsg {
    NSLog(@"蓝牙错误   :%ld",(long)error);
    dispatch_main_async(^{
        [self.commandDict enumerateKeysAndObjectsUsingBlock:^(NSNumber*  _Nonnull command, BLECompletion  _Nonnull completion, BOOL * _Nonnull stop) {
            if (command.intValue != BLECommandScan) {
                completion(false,[self errorWithCode:error]);
            }
        }];
        
        BLECompletion scanCommand = self.commandDict[@(BLECommandScan)];
        [self.commandDict removeAllObjects];
        if (scanCommand) self.commandDict[@(BLECommandScan)] = scanCommand;
        
        if (command == 2) {//升级锁失败
//            NOTIF_POST(PTBLE_NOTIFICATION_UPGRADE_ERROR, nil);
        }
        
#warning todo 发送通知 上传错误报告
    });
}

- (void)onFoundDevice_peripheralWithInfoDic:(NSDictionary *)infoDic {
    if (_currentPeripheral) return;
    
    CBPeripheral *peripheral = infoDic[@"peripheral"];
    NSString *rssi = infoDic[@"rssi"];
//    NSInteger unlockRssi = [infoDic[@"oneMeterRSSI"] intValue];
    NSString *lockName = infoDic[@"lockName"];
    NSString *mac = infoDic[@"mac"];
    BOOL isContainAdmin = [infoDic[@"isContainAdmin"] boolValue];
    NSInteger protocolCategory = [infoDic[@"protocolCategory"] integerValue];
    NSString *protocolType = infoDic[@"protocolType"];
    NSString *protocolVersion = infoDic[@"protocolVersion"];
//    NSDictionary *advertisementData = infoDic[@"advertisementData"];
    BOOL isAllowUnlock = [infoDic[@"isAllowUnlock"] boolValue];
//    BOOL isDfuMode = [infoDic[@"isDfuMode"] boolValue];
    
    if (protocolType.integerValue != 5 || protocolVersion.integerValue != 3) return;
    
    if (_commandDict[@(BLECommandScan)]) {//添加锁
        if (mac.length && protocolCategory == 5) {
            [self scanPeripheral:peripheral mac:mac rssi:rssi lockName:lockName isContainAdmin:isContainAdmin isTouch:isAllowUnlock protocolType:protocolType protocolVersion:protocolVersion];
        }
    }
}

- (void)onBTConnectSuccess_peripheral:(CBPeripheral *)peripheral lockName:(NSString *)lockName {
    if (_currentPeripheral) return;
    NSLog(@"蓝牙连接成功");
     _currentPeripheral = peripheral;
    //停止扫描
    [_ttlock stopBTDeviceScan];
    //设置用户id
    _ttlock.uid = _uid;
    //震动
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    //成功回调
    BLECompletion connectCompletion = _commandDict[@(BLECommandConnect)];
    if (connectCompletion) {
        [_commandDict removeObjectForKey:@(BLECommandConnect)];
        dispatch_main_async(^{
            connectCompletion(true,nil);
        });
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)onBTDisconnect_peripheral:(CBPeripheral *)periphera {
    NSLog(@"蓝牙断开连接");
    dispatch_main_async(^{
        [self.commandDict enumerateKeysAndObjectsUsingBlock:^(NSNumber*  _Nonnull command, BLECompletion  _Nonnull completion, BOOL * _Nonnull stop) {
            if (command.intValue != BLECommandScan) {
                completion(false,@"蓝牙连接中断，请再次尝试");
            }
        }];
        
        BLECompletion scanCommand = self.commandDict[@(BLECommandScan)];
        [self.commandDict removeAllObjects];
        if (scanCommand) self.commandDict[@(BLECommandScan)] = scanCommand;
        
        if (scanCommand != nil || self.touchUnlock) {
            [self.ttlock startBTDeviceScan:false];
        }
        self.currentPeripheral = nil;
        self.currentKey = nil;
    });
}

- (void)onLockInitializeWithLockData:(NSString *)lockData{
    _currentKey = [LockModel yy_modelWithJSON:lockData];
    BLECompletion completion = _commandDict[@(BLECommandAddLock)];
    if (completion) {
        [_commandDict removeObjectForKey:@(BLECommandAddLock)];
        dispatch_main_async(^{
            completion(true,lockData);
        });
    }
}

- (void)onSetNBServer{
    NSLog(@"设置NB锁地址 端口 成功");
    BLECompletion completion = _commandDict[@(BLECommandSetNB)];
    if (completion) {
        [_commandDict removeObjectForKey:@(BLECommandSetNB)];
        dispatch_main_async(^{
            completion(true,nil);
        });
    }
}

//开门成功
- (void)onUnlockWithLockTime:(NSTimeInterval)lockTime electricQuantity:(int)electricQuantity {
    NSLog(@"开门成功 :%f",lockTime);
    
    BLECompletion completion = _commandDict[@(BLECommandUnlock)];
    if (completion) {
        [_commandDict removeObjectForKey:@(BLECommandUnlock)];
        dispatch_main_async(^{
            completion(true,nil);
        });
        
        {//播放开么声音
//            NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/sound_unlock.mp3",NSBundle.mainBundle.resourcePath]];
//            SystemSoundID systemSoundID = 0;
//            AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &systemSoundID);
//            AudioServicesPlayAlertSound(systemSoundID);
        }
        
        if (electricQuantity < 20) {//低电量提示
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [self onLowPower];
//            });
        }
    }
    
    {//上传开锁记录
#warning todo
//        [PTNetWork uploadUnlockLockId:_currentKey.lockId keyId:_currentKey.keyId electricQuantity:electricQuantity uniqueid:_uniqueid.longLongValue lockDate:lockTime completion:nil];
    }
}

- (void)onLowPower{
    NSLog(@"低电量提示");
    {//播放开么声音
        NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sound_for_lock_no_power" ofType:@"mp3"]];
        SystemSoundID systemSoundID = 0;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &systemSoundID);
        AudioServicesPlayAlertSound(systemSoundID);
    }
}


//读取操作记录
- (void)onGetOperateLog_LockOpenRecordStr:(NSString *)LockOpenRecordStr {
    //操作记录
    BLECompletion unlockRecordBlock = _commandDict[@(BLECommandGetRecord)];
    [_commandDict removeObjectForKey:@(BLECommandGetRecord)];
    //读取 IC 指纹  密码
    BLECompletion storageDataBlock = _commandDict[@(BLECommandGetStorageData)];
    [_commandDict removeObjectForKey:@(BLECommandGetStorageData)];
    if (unlockRecordBlock) {
        NSLog(@"读取操作记录成功 :%@",LockOpenRecordStr);
        dispatch_main_async(^{
            unlockRecordBlock(true,LockOpenRecordStr);
        });
        if (LockOpenRecordStr){//上传操作记录
#warning todo
//            [PTNetWork uploadUnlockLockId:_currentKey.lockId records:LockOpenRecordStr completion:nil];
        }
    }else if (storageDataBlock){
        NSLog(@"读取  IC 指纹  密码 %@",LockOpenRecordStr);
        dispatch_main_async(^{
            storageDataBlock(true,LockOpenRecordStr);
        });
    }
}

//设置锁时间
- (void)onSetLockTime {
    NSLog(@"设置锁时间成功");
    BLECompletion completion = _commandDict[@(BLECommandSetTime)];
    if (completion) {
        [_commandDict removeObjectForKey:@(BLECommandSetTime)];
        dispatch_main_async(^{
            completion(true,nil);
        });
    }
}

- (void)onResetLock{
    
    NSLog(@"恢复出厂设置成功");
    BLECompletion completion = _commandDict[@(BLECommandResetLock)];
    if (completion) {
        [_commandDict removeObjectForKey:@(BLECommandResetLock)];
        dispatch_main_async(^{
            completion(true,nil);
        });
    }
}

- (void)onGetLockTime:(NSTimeInterval)lockTime{
    NSLog(@"获取锁时间成功 %f",lockTime);
    BLECompletion completion = _commandDict[@(BLECommandGetTime)];
    if (completion) {
        [_commandDict removeObjectForKey:@(BLECommandGetTime)];
        dispatch_main_async(^{
            completion(true,@(lockTime));
        });
    }
}

- (void)onGetDeviceCharacteristic:(long long)characteristic{
    NSLog(@"读取锁特征值：%lld",characteristic);
    BLECompletion lockInfoBlock = _commandDict[@(BLECommandGetSpecialValue)];
    [_commandDict removeObjectForKey:[NSString stringWithFormat:@"%lld",characteristic]];
    if (lockInfoBlock){
        dispatch_main_async(^{
            lockInfoBlock(true,@(characteristic));
        });
    }
}

- (void)onGetDeviceInfo:(NSMutableDictionary *)infoDic{
    NSLog(@"读取锁固件信息：%@",infoDic);
    BLECompletion lockInfoBlock = _commandDict[@(BLECommandGetSystem)];
    [_commandDict removeObjectForKey:@(BLECommandGetSystem)];
    if (lockInfoBlock){
        dispatch_main_async(^{
            lockInfoBlock(true,infoDic);
        });
    }
}

- (void)onEnterFirmwareUpgradeMode{
    NSLog(@"锁被激活 进入升级状态");
    BLECompletion upgradeBlock = _commandDict[@(BLECommandActiveUpgrade)];
    [_commandDict removeObjectForKey:@(BLECommandActiveUpgrade)];
    if (upgradeBlock){
        dispatch_main_async(^{
            upgradeBlock(true,self.currentPeripheral);
        });
    }
}

- (void)onRecoverUserKeyBoardPassword{
    NSLog(@"恢复密码成功");
    BLECompletion coverPswBlock = _commandDict[@(BLECommandRecoverPassword)];
    [_commandDict removeObjectForKey:@(BLECommandRecoverPassword)];
    if (coverPswBlock){
        dispatch_main_async(^{
            coverPswBlock(true,nil);
        });
    }
}

#pragma mark IC卡
- (void)onAddICWithState:(AddICState)state ICNumber:(NSString *)ICNumber{
    NSLog(@"添加IC卡 状态：%ld  number:%@",(long)state,ICNumber);
    BLECompletion setupDevBlock = _commandDict[@(BLECommandAccessoryAdd)];
    if (setupDevBlock){
        dispatch_main_async(^{
            if (state == AddICStateHadAdd && ICNumber.length) {
                [self.commandDict removeObjectForKey:@(BLECommandAccessoryAdd)];
            }
            setupDevBlock(true,@{@"number":ICNumber,@"state":@(state)});
        });
    }
}

- (void)onClearIC{
    NSLog(@"清空IC卡 ");
    BLECompletion setupDevBlock = _commandDict[@(BLECommandAccessClear)];
    [_commandDict removeObjectForKey:@(BLECommandAccessClear)];
    if (setupDevBlock){
        dispatch_main_async(^{
            setupDevBlock(true,nil);
        });
    }
}

- (void)onDeleteIC{
    NSLog(@"删除IC卡 成功");
    BLECompletion setupDevBlock = _commandDict[@(BLECommandAccessDelete)];
    [_commandDict removeObjectForKey:@(BLECommandAccessDelete)];
    if (setupDevBlock){
        dispatch_main_async(^{
            setupDevBlock(true,nil);
        });
    }
}

- (void)onModifyIC{
    NSLog(@"修改IC卡 ");
    BLECompletion setupDevBlock = _commandDict[@(BLECommandAccessModify)];
    [_commandDict removeObjectForKey:@(BLECommandAccessModify)];
    if (setupDevBlock){
        dispatch_main_async(^{
            setupDevBlock(true,nil);
        });
    }
}

#pragma mark 指纹 以后才有的指令回调

- (void)onAddFingerprintWithState:(AddFingerprintState)state fingerprintNumber:(NSString*)fingerprintNumber{
    NSLog(@"添加指纹 状态：%ld  number:%@",(long)state,fingerprintNumber);
    BLECompletion setupDevBlock = _commandDict[@(BLECommandAccessoryAdd)];
    if (setupDevBlock){
        dispatch_main_async(^{
            if (fingerprintNumber.length && state == AddFingerprintCollectSuccess) {
                [self.commandDict removeObjectForKey:@(BLECommandAccessoryAdd)];
            }
            setupDevBlock(true,@{@"number":fingerprintNumber ?:@"",@"state":@(state)});
        });
    }
}

- (void)onClearFingerprint{
    NSLog(@"清空IC卡 ");
    BLECompletion setupDevBlock = _commandDict[@(BLECommandAccessClear)];
    [_commandDict removeObjectForKey:@(BLECommandAccessClear)];
    if (setupDevBlock){
        dispatch_main_async(^{
            setupDevBlock(true,nil);
        });
    }
}

- (void)onDeleteFingerprint{
    NSLog(@"删除IC卡 ");
    BLECompletion setupDevBlock = _commandDict[@(BLECommandAccessDelete)];
    [_commandDict removeObjectForKey:@(BLECommandAccessDelete)];
    if (setupDevBlock){
        dispatch_main_async(^{
            setupDevBlock(true,nil);
        });
    }
}

- (void)onModifyFingerprint{
    NSLog(@"修改IC卡 ");
    BLECompletion setupDevBlock = _commandDict[@(BLECommandAccessModify)];
    [_commandDict removeObjectForKey:@(BLECommandAccessModify)];
    if (setupDevBlock){
        dispatch_main_async(^{
            setupDevBlock(true,nil);
        });
    }
}

#pragma mark - DFU 升级


#pragma mark - Private

- (void)scanPeripheral:(CBPeripheral *)peripheral mac:(NSString *)mac rssi:(NSString *)rssi lockName:(NSString *)lockName isContainAdmin:(BOOL)isContainAdmin isTouch:(BOOL)isTouch protocolType:(NSString *)protocolType protocolVersion:(NSString *)protocolVersion{
    
//    __block OSSpinLock oslock = OS_SPINLOCK_INIT;
//    OSSpinLockLock(&oslock);
//
//    BOOL isCallBack = false;
//    BOOL haveContainModel = false;
//    for (ScanModel  *model in self.addLockModelArray) {
//        if ([model.lockMac isEqualToString:mac]) {
//            model.date = [[NSDate date] timeIntervalSince1970];
//            haveContainModel = true;
//            if (model.isContainAdmin != isContainAdmin) {
//                model.isContainAdmin = isContainAdmin;
//                isCallBack = true;
//            }
//            break;
//        }
//    }
//    if (haveContainModel == false && peripheral.name) {
//        isCallBack = true;
//
//        ScanModel *model = [ScanModel new];
//        model.uuidString = peripheral.identifier.UUIDString;
//        model.rssi = rssi;
//        model.lockName = peripheral.name;
//        model.lockMac = mac;
//        model.isContainAdmin = isContainAdmin;
//        model.protocolType = protocolType;
//        model.protocolVersion = protocolVersion;
//        model.date = [[NSDate date] timeIntervalSince1970];
//        [self.addLockModelArray addObject:model ];
//    }
//    OSSpinLockUnlock(&oslock);
//
//    for (ScanModel  *model in self.addLockModelArray) {
//        if (model.date - [[NSDate date] timeIntervalSince1970] < -5 && model.isContainAdmin == false) {
//            model.isContainAdmin = true;
//        }
//    }
//
//    [self.addLockModelArray sortUsingComparator:^NSComparisonResult(ScanModel *obj1, ScanModel * obj2) {
//        return (obj1.rssi > obj2.rssi);
//    }];
//    [self.addLockModelArray sortUsingComparator:^NSComparisonResult(ScanModel *obj1, ScanModel * obj2) {
//        int i = obj1.isContainAdmin ? 1 : 0;
//        int j = obj2.isContainAdmin ? 1 : 0;
//        return (i > j);
//    }];
//
    
    if (lockName && mac) {
        ScanModel *model = [ScanModel new];
        model.rssi = rssi.integerValue;
        model.lockName = lockName;
        model.lockMac = mac;
        model.isSettingMode = !isContainAdmin;
        model.isTouch = isTouch;
        model.protocolType = protocolType;
        model.protocolVersion = protocolVersion;
        
        BLECompletion scanCommand = self.commandDict[@(BLECommandScan)];
        dispatch_main_async(^{
            scanCommand(true,model);
        });
    }
}

- (void)scanDFUPeripheral:(CBPeripheral *)peripheral isDfuMode:(BOOL)isDfuMode{
    [NSRunLoop cancelPreviousPerformRequestsWithTarget:self selector:@selector(scanDFUTimeOut) object:nil];
    _scanDFUArray = nil;
    _isScanDFUTimeOut = false;
    _scanMac = nil;
    [_ttlock stopBTDeviceScan];
    
//    ScanModel *model = [ScanModel new];
//    model.uuidString = peripheral.identifier.UUIDString;
//    model.isDfuMode = isDfuMode;
//    BLECompletion completion = _commandDict[@(BLECommandScanMac)];
//    if (completion) {
//        [_commandDict removeObjectForKey:@(BLECommandScanMac)];
//        dispatch_main_async(^{
//            completion(true,model);
//        });
//    }
}

- (NSError *)errorWithCode:(TTError)code {
    NSMutableString *errorString = @"操作失败 ".mutableCopy;
    switch (code) {
        case TTErrorHadReseted:
            [errorString appendString:@"锁可能已被重置"];
            break;
        case TTErrorDataCRCError:
            
            break;
        case TTErrorNoPermisston:
            
            break;
        case TTErrorIsWrongPS:
            
            break;
        case TTErrorNoMemory:
            [errorString appendString:@"锁内存空间不够"];
            break;
        case TTErrorInSettingMode:
            
            break;
        case TTErrorNoAdmin:
            [errorString appendString:@"管理员不存在"];
            break;
        case TTErrorIsNotSettingMode:
            
            break;
        case TTErrorIsWrongDynamicPS:
            
            break;
        case TTErrorIsNoPower:
            [errorString appendString:@"锁电量不足"];
            break;
        case TTErrorResetKeyboardPs:
            
            break;
        case TTErrorUpdateKeyboardIndex:
            
            break;
        case TTErrorIsInvalidFlag:
            [errorString appendString:@"电子钥匙已被重置"];
            break;
        case TTErrorEkeyOutOfDate:
            [errorString appendString:@"电子钥匙已过期"];
            break;
        case TTErrorPasswordLengthInvalid:
            [errorString appendString:@"密码长度无效"];
            break;
        case TTErrorSuperPasswordIsSameWithDeletePassword:
            [errorString appendString:@"管理员密码与删除密码相等"];
            break;
        case TTErrorEkeyNotToDate:
            [errorString appendString:@"电子钥匙未到有效期"];
            break;
        case TTErrorAesKey:
            
            break;
        case TTErrorPasswordNotExist:
            [errorString appendString:@"密码不存在"];
            break;
        case TTErrorPsswordExist:
            [errorString appendString:@"密码已存在"];
            break;
        case TTErrorNoFree_Memory:
            [errorString appendString:@"内存空间不足"];
            break;
        case TTErrorCardNotExist:
            [errorString appendString:@"IC卡不存在"];
            break;
        case TTErrorFingerprintDuplication:
            [errorString appendString:@"指纹重复"];
            break;
        case TTErrorFingerprintNotExist:
            [errorString appendString:@"指纹不存在"];
            break;
        default:
            break;
    }
    NSError *error = [NSError errorWithDomain:@"PTBLE" code:code userInfo:@{NSLocalizedDescriptionKey: errorString}];
    return error;
}

+ (NSString *)decodeKeyboardPwd:(NSString *)keyboardPwd{
    return [TTUtils DecodeSharedKeyValue:[SecurityUtil decodeBase64String:keyboardPwd]];
}

+ (NSString *)encodeKeyboardPwd:(NSString *)keyboardPwd{
    return [SecurityUtil encodeBase64String:[TTUtils EncodeSharedKeyValue:keyboardPwd]];
}

void dispatch_main_async(dispatch_block_t block) {
  dispatch_async(dispatch_get_main_queue(), ^(){
    if (block) {
      @autoreleasepool {
        block();
      }
    }
  });
}

void dispatch_global_async(dispatch_block_t block) {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
    if (block) {
      @autoreleasepool {
        block();
      }
    }
  });
}

@end


#pragma mark - Private
@implementation NSMutableDictionary (Helper)
- (void)setObjectSafe:(id)object forKey:(id)key {
  if (nil == key) return ;
  if (object) {
    [self setObject:object forKey:key];
  }else{
    [self removeObjectForKey:key];
  }
}
@end


@implementation NSArray (Helper)
- (id)objectAtIndexSafe:(NSInteger)index {
  if (index < self.count && index >= 0) {
    return [self objectAtIndex:index];
  }else{
    return nil;
  }
}
@end
