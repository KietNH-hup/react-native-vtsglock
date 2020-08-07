//
//  TtLockModule.m
//  HelloRN
//
//  Created by Jinbo Lu on 2018/9/17.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "TtLockModule.h"
#import "PTBLE.h"

typedef NS_ENUM(NSInteger,TTLockOption){
    TTLockOptionInitLock = 1,
    TTLockOptionUnlock,

    TTLockOptionGetRecordLog,
    TTLockOptionResetLock,
    // ahmad
    TTLockOptionSetTime,
    TTLockOptionSetAdminPassword,
    TTLockOptionUnlockByAdministrator,
    TTLockOptionResetKeyboardPassword,

    TTLockOptionGetAudioState,
    TTLockOptionSetAudioState,

    TTLockOptionAddPeriodKeyboardPassword,
    TTLockOptionDeleteOneKeyboardPassword,
};

@interface TtLockModule()
@property (strong) NSMutableArray *scanModelArray;
@end


@implementation TtLockModule
RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(initTTlockApi){
    [[PTBLE shareInstance] setUid:[NSString stringWithFormat:@"%ld",0]];
}

- (NSArray<NSString *> *)supportedEvents{

  return @[@"ScanBtDeviceEvent"];
}


RCT_EXPORT_METHOD(startBTDeviceScan){
    self.scanModelArray = @[].mutableCopy;
  [[PTBLE shareInstance] scan:^(BOOL success, id info) {

    if (success) {
        [self cacheScanModel:info];
        [self sendEventWithName:@"ScanBtDeviceEvent" body:[info yy_modelToJSONObject]];
    }
  }];
}

RCT_EXPORT_METHOD(stopBTDeviceScan){
    [[PTBLE shareInstance] stopScan];
    self.scanModelArray = nil;
}

RCT_EXPORT_METHOD(disconnect){
  [[PTBLE shareInstance] disconnect];
}

RCT_EXPORT_METHOD(lockInitialize:(NSString *)mac
                  callBlock:(RCTResponseSenderBlock)callBlock){
    LockModel *lockModel = [LockModel new];
    lockModel.lockMac = mac;
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:nil option:TTLockOptionInitLock callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:nil option:TTLockOptionInitLock callBlock:callBlock];
    }
}

RCT_EXPORT_METHOD(unlockByUser:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock){
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:nil option:TTLockOptionUnlock callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:nil option:TTLockOptionUnlock callBlock:callBlock];
    }
}


RCT_EXPORT_METHOD(getOperateLog:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock){
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:nil option:TTLockOptionGetRecordLog callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:nil option:TTLockOptionGetRecordLog callBlock:callBlock];
    }
}

RCT_EXPORT_METHOD(resetLock:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock){
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:nil option:TTLockOptionResetLock callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:nil option:TTLockOptionResetLock callBlock:callBlock];
    }
}


//ahmad
RCT_EXPORT_METHOD(unlockByAdministrator:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock)
{
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:nil option:TTLockOptionUnlockByAdministrator callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:nil option:TTLockOptionUnlockByAdministrator callBlock:callBlock];
    }
}

//ahmad
RCT_EXPORT_METHOD(resetKeyboardPassword:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock)
{
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:nil option:TTLockOptionResetKeyboardPassword callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:nil option:TTLockOptionResetKeyboardPassword callBlock:callBlock];
    }
}


// ahmad : add timezone
RCT_EXPORT_METHOD(setLockTime:(double)time timezoneRawOffset:(double)timezoneRawOffset lockJsonString:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock)
{
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];
    NSDictionary *param = @{
                            @"time":@(time),
                            @"timezoneRawOffset":@(timezoneRawOffset),

                            };
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:param option:TTLockOptionSetTime callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:param option:TTLockOptionSetTime callBlock:callBlock];
    }
}
// ahmad
RCT_EXPORT_METHOD(setAdminKeyboardPassword:(NSString *)pin lockJsonString:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock)
{
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];
    NSDictionary *param = @{@"pin":pin};
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:param option:TTLockOptionSetAdminPassword callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:param option:TTLockOptionSetAdminPassword callBlock:callBlock];
    }
}


// ahmad
RCT_EXPORT_METHOD(setLockAudioState:(BOOL)isOn lockJsonString:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock)
{
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];
    NSDictionary *param =  @{@"isOn":@(isOn)};
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:param option:TTLockOptionSetAudioState callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:param option:TTLockOptionSetAudioState callBlock:callBlock];
    }
}

// ahmad
RCT_EXPORT_METHOD(getLockAudioState:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock)
{
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];

    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:nil option:TTLockOptionGetAudioState callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:nil option:TTLockOptionGetAudioState callBlock:callBlock];
    }
}




// ahmad : add pin
RCT_EXPORT_METHOD(addPeriodKeyboardPassword:(NSString *)pin
                  startTimestamp:(double)startTimestamp
                  endTimestamp:(double)endTimestamp
                  lockJsonString:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock)
{
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];
    NSDictionary *param = @{
                            @"pin":pin,
                            @"startTimestamp":@(startTimestamp),
                            @"endTimestamp":@(endTimestamp),
                            };
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:param option:TTLockOptionAddPeriodKeyboardPassword callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:param option:TTLockOptionAddPeriodKeyboardPassword callBlock:callBlock];
    }
}

// ahmad : delete pin
RCT_EXPORT_METHOD(deleteOneKeyboardPassword:(NSString *)pin
                  lockJsonString:(NSString *)lockJsonString callBlock:(RCTResponseSenderBlock)callBlock)
{
    LockModel *lockModel = [LockModel yy_modelWithJSON:lockJsonString];
    NSDictionary *param = @{
                            @"pin":pin,
                            };
    if ([PTBLE shareInstance].isBLEConnected) {
        [self lock:lockModel param:param option:TTLockOptionDeleteOneKeyboardPassword callBlock:callBlock];
    }else{
        [self connectLock:lockModel param:param option:TTLockOptionDeleteOneKeyboardPassword callBlock:callBlock];
    }
}

#pragma mark - Private

- (void)connectLock:(LockModel *)lock param:(NSDictionary *)param option:(TTLockOption)option callBlock:(RCTResponseSenderBlock)callBlock{
    [[PTBLE shareInstance] connectMac:lock.lockMac completion:^(BOOL success, id info) {
        if (callBlock) {
            if (success) {
                [self lock:lock param:param option:option callBlock:callBlock];
            }else{
                callBlock(@[[self optionSuccess:success info:info]]);
            }
        }
    }];
}



- (void)lock:(LockModel *)lock param:(NSDictionary *)param option:(TTLockOption)option callBlock:(RCTResponseSenderBlock)callBlock{
    switch (option) {
        case TTLockOptionInitLock:
        {
            ScanModel *scanModel = nil;
            for (ScanModel *model in self.scanModelArray) {
                if ([model.lockMac isEqualToString:lock.lockMac]) {
                    scanModel = model;
                    break;
                }
            }
            [[PTBLE shareInstance] addLock:scanModel completion:^(BOOL success, id info) {
                id data = success ? @{@"lockDataJsonString":info ? info :@""} : info;
                callBlock(@[[self optionSuccess:success info:data]]);
            }];
        }
            break;
        case TTLockOptionUnlock:
        {
            [[PTBLE shareInstance] unlockKey:lock completion:^(BOOL success, id info) {
                callBlock(@[[self optionSuccess:success info:info]]);
            }];
        }
            break;



        case TTLockOptionGetRecordLog:
        {
            [[PTBLE shareInstance] getUnlockRecordKey:lock completion:^(BOOL success, id info) {
                id data = success ? @{@"lockOperateLog":info?:@""} : info;
                callBlock(@[[self optionSuccess:success info:data]]);
            }];
        }
            break;
        case TTLockOptionResetLock:
        {
            [[PTBLE shareInstance] resetLockKey:lock completion:^(BOOL success, id info) {
                callBlock(@[[self optionSuccess:success info:info]]);
            }];
        }
            break;

        // ahmad
        case TTLockOptionSetAdminPassword:
        {
            [[PTBLE shareInstance] setAdminKeyBoardPassword:[param[@"pin"] stringValue] key:lock completion:^(BOOL success, id info) {
                callBlock(@[[self optionSuccess:success info:info]]);
            }];
            break;
        }

        // ahmad
        case TTLockOptionSetTime:
        {
            [[PTBLE shareInstance] setLockTimeValue:[param[@"time"] doubleValue]
                                  timezoneRawOffset:[param[@"timezoneRawOffset"] doubleValue]
                                                key:lock
                                         completion:^(BOOL success, id info) {
                callBlock(@[[self optionSuccess:success info:info]]);
            }];
        }
            break;


        // ahmad
        case TTLockOptionUnlockByAdministrator:
        {
            [[PTBLE shareInstance] unlockByAdministrator:lock completion:^(BOOL success, id info) {
                callBlock(@[[self optionSuccess:success info:info]]);
            }];
        }
            break;



        //ahmad
        case TTLockOptionResetKeyboardPassword:
        {
            [[PTBLE shareInstance] resetKeyboardPassword:lock completion:^(BOOL success, id info) {
                callBlock(@[[self optionSuccess:success info:info]]);
            }];

        }
            break;

        // ahmad
        case TTLockOptionGetAudioState:
        {
            [[PTBLE shareInstance] getLockAudioState:lock completion:^(BOOL success, id info) {
                 callBlock(@[[self optionSuccess:success info:info]]);
            }];
        }
            break;


        // ahmad
        case TTLockOptionSetAudioState:
        {
            [[PTBLE shareInstance] setLockAudioState:[param[@"isOn"] boolValue]
                                key:lock
                                completion:^(BOOL success, id info) {
                                callBlock(@[[self optionSuccess:success info:info]]);
                                }
             ];
        }
            break;

          // ahmad
        case TTLockOptionAddPeriodKeyboardPassword:
        {
            [[PTBLE shareInstance] addPeriodKeyboardPassword:[param[@"pin"] stringValue]
                                              startTimestamp:[param[@"startTimestamp"] doubleValue]
                                                endTimestamp:[param[@"endTimestamp"] doubleValue]
                                                         key:lock
                                                  completion:^(BOOL success, id info) {
                    callBlock(@[[self optionSuccess:success info:info]]);
            }];
        }
            break;

         // ahmad
        case TTLockOptionDeleteOneKeyboardPassword:
        {
            [[PTBLE shareInstance] deleteOneKeyboardPassword:[param[@"pin"] stringValue]
                                                         key:lock
                                                  completion:^(BOOL success, id info) {
                    callBlock(@[[self optionSuccess:success info:info]]);
            }];
        }
        break;



        default:
            break;
    }
}

- (NSDictionary *)optionSuccess:(BOOL)success info:(id)info{
    NSMutableDictionary *dict = @{}.mutableCopy;
    dict[@"success"] = @(success);
    if (success) {
        if (info) [dict setValuesForKeysWithDictionary:info];
    }else{
        if ([info isKindOfClass:[NSError class]]) {
            NSError *error = (NSError *)info;
            dict[@"code"] = [NSString stringWithFormat:@"%ld",error.code];
            dict[@"message"] = error.userInfo[NSLocalizedDescriptionKey];
        }else if([info isKindOfClass:[NSString class]]){
            dict[@"message"] = info;
            dict[@"code"] = @"100010";
        }
    }

    return dict;
}

- (void)cacheScanModel:(ScanModel *)scanModel{
    if (scanModel == nil) return;
    BOOL isContainScan = NO;
    ScanModel *containScanModel = nil;
    for (ScanModel *model in self.scanModelArray) {
        if ([model.lockMac isEqualToString:scanModel.lockMac]) {
            isContainScan = true;
            containScanModel = scanModel;
            break;
        }
    }
    if (isContainScan) {
        containScanModel.rssi = scanModel.rssi;
        containScanModel.isTouch = scanModel.isTouch;
        containScanModel.isSettingMode = scanModel.isSettingMode;
    }else{
        [self.scanModelArray addObject:scanModel];
    }
}

@end

