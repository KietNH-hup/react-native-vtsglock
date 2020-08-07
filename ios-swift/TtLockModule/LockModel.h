//
//  PHLockModel.h
//  PublicHouse
//
//  Created by Jinbo Lu on 2018/7/11.
//  Copyright © 2018年 HangZhouSciener. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YYModel.h"

@interface ScanModel : NSObject

/**蓝牙的mac地址*/
@property (nonatomic,strong)NSString *lockMac;
/**蓝牙的mac*/
@property (nonatomic,strong)NSString *lockName;
/**蓝牙信号强度*/
@property (nonatomic, assign) NSInteger rssi;
/**锁是否被摸亮*/
@property (nonatomic, assign) BOOL isTouch;
/**是否可添加状态*/
@property (nonatomic, assign) BOOL isSettingMode;

@property (nonatomic, strong) NSString *protocolType;
@property (nonatomic, strong) NSString *protocolVersion;
@end

@interface LockModel : NSObject
@property (nonatomic, strong) NSString *keyId;
@property (nonatomic, strong) NSString *lockId;
@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *noKeyPwd;
@property (nonatomic, strong) NSString *lockAlias;
@property (nonatomic, strong) NSString *keyStatus;
@property (nonatomic, strong) NSString *lockName;
@property (nonatomic, strong) NSString *lockKey;
@property (nonatomic, strong) NSString *lockMac;
@property (nonatomic, strong) NSString *lockVersion;
@property (nonatomic, strong) NSString *aesKeyStr;
@property (nonatomic, strong) NSString *adminPwd;
@property (nonatomic, strong) NSString *deletePwd;
@property (nonatomic, strong) NSString *lockFlagPos;
@property (nonatomic, strong) NSString *specialValue;
@property (nonatomic, strong) NSString *electricQuantity;
@property (nonatomic, strong) NSString *startDate;
@property (nonatomic, strong) NSString *endDate;
@property (nonatomic, strong) NSString *protocolType;
@property (nonatomic, strong) NSString *protocolVersion;
@property (nonatomic, strong) NSString *scene;
@property (nonatomic, strong) NSString *groupId;
@property (nonatomic, strong) NSString *orgId;

@property (nonatomic, strong) NSString *timezoneRawOffset;

@property (nonatomic, strong) NSString *modelNum;
@property (nonatomic, strong) NSString *pwdInfo;
@property (nonatomic, strong) NSString *hardwareRevision;
@property (nonatomic, strong) NSString *firmwareRevision;
@property (nonatomic, strong) NSString *nbNodeId;
@property (nonatomic, strong) NSString *nbCardNumber;
@property (nonatomic, strong) NSString *nbRssi;
@property (nonatomic, strong) NSString *nbOperator;
@property (nonatomic, strong) NSString *timestamp;

@property (nonatomic, strong) NSString *version;
@end
