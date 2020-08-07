import {DeviceEventEmitter, NativeEventEmitter, NativeModules, Platform} from 'react-native';

const TipiLockModule = Platform.OS === 'ios'
    ? NativeModules.TtLockModule
    : NativeModules.TipiLockModule;

const TipiLockIOSEmitter = new NativeEventEmitter(TipiLockModule);

let listener = {}
const androidReceiverLockDeviceScanEvent = "ScanLockDeviceEvent";
const iOSeceiverLockDeviceScanEvent = "ScanBtDeviceEvent";
const PlatformAndroid = "android";
const PlatformIOS = "ios"

export default class TipiLock {
    static init() {
        if (Platform.OS === 'android') {
            TipiLockModule.init();
            TipiLockModule.startBleService()
        } else if (Platform.OS === 'ios') {
            TipiLockModule.initTTlockApi()
            // return TipiLockModule.initialise();
        }
    }

    /**
     * Android Only
     */
    static startBleService() {
        TipiLockModule.startBleService()
    }

    /**
     * Android Only
     */
    static stopBleService() {
        TipiLockModule.stopBleService()
    }

    static startDeviceScan() {
        if (Platform.OS === 'ios')
            TipiLockModule.startBTDeviceScan()
        else
            TipiLockModule.startDeviceScan()
    }

    static stopDeviceScan() {
        if (Platform.OS === 'ios')
            TipiLockModule.stopBTDeviceScan()
        else
            TipiLockModule.stopDeviceScan()
    }

    static lockInitialize(lockMac, callback) {
        TipiLockModule.lockInitialize(lockMac, callback)
    }

    static setLockTime(timestamp, timeZoneOffset, lock, callback) {
        // if (Platform.OS === 'android')
        TipiLockModule.setLockTime(Number(timestamp), Number(timeZoneOffset), this.normalizeLockData(lock), this.normalizeCallback(callback))
        // else
        //     TipiLockModule.setLockTime(Number(timestamp), this.normalizeLockData(lock), callback)
    }

    static getLockTime(lock, callback) {
        if (Platform.OS === 'android')
            TipiLockModule.getLockTime(this.normalizeLockData(lock), this.normalizeCallback(callback))
        else {
            callback && callback({
                success: false, message: 'Not Implemented Yet.'
            })
        }
    }

    static resetLock(lock, callback) {
        TipiLockModule.resetLock(this.normalizeLockData(lock), this.normalizeCallback(callback))
    }

    static unlockByAdministrator(lock, callback) {
        // if (Platform.OS === 'android')
        TipiLockModule.unlockByAdministrator(this.normalizeLockData(lock), this.normalizeCallback(callback))
    }

    static unlockByUser(lock, callback) {
        TipiLockModule.unlockByUser(this.normalizeLockData(lock), this.normalizeCallback(callback))
    }

    static getOperateLog(lock, callback) {
        TipiLockModule.getOperateLog(this.normalizeLockData(lock), this.normalizeCallback(callback))
    }

    static addPeriodKeyboardPassword(pin, startTimestamp, endTimestamp, lock, callback) {
        // if (Platform.OS === 'android')
        TipiLockModule.addPeriodKeyboardPassword(
            String(pin),
            Number(startTimestamp),
            Number(endTimestamp),
            this.normalizeLockData(lock),
            this.normalizeCallback(callback)
        )
    }

    static modifyKeyboardPassword(oldPin, newPin, startTimestamp, endTimestamp, lock, callback) {
        if (Platform.OS === 'android')
            TipiLockModule.modifyKeyboardPassword(
                String(oldPin),
                String(newPin),
                Number(startTimestamp),
                Number(endTimestamp),
                this.normalizeLockData(lock),
                this.normalizeCallback(callback)
            )
    }

    static deleteOneKeyboardPassword(pin, lock, callback) {
        TipiLockModule.deleteOneKeyboardPassword(
            String(pin),
            this.normalizeLockData(lock),
            this.normalizeCallback(callback)
        )
    }

    static resetKeyboardPassword(lock, callback) {
        // if (Platform.OS === 'android')
        TipiLockModule.resetKeyboardPassword(this.normalizeLockData(lock), this.normalizeCallback(callback))
    }

    static setAdminKeyboardPassword(pin, lock, callback) {
        // if (Platform.OS === 'android')
        TipiLockModule.setAdminKeyboardPassword(String(pin), this.normalizeLockData(lock), this.normalizeCallback(callback))
        // if (Platform.OS === 'ios') {
        //
        // }
    }

    // static operateAudioSwitch(operateType, state, lock, callback) {
    //     if (Platform.OS === 'android')
    //         TipiLockModule.operateAudioSwitch(operateType, state, this.normalizeLockData(lock), this.normalizeCallback(callback))
    //     else {
    //         callback && callback({
    //             success: false, message: 'Not Implemented Yet.'
    //         })
    //     }
    // }

    static getAudioState(lock, callback) {
        let _callback = this.normalizeCallback((info) => {
            let isOn = !!info.isOn || info.state === 1;
            callback && callback({...info, isOn});
        })

        if (Platform.OS === 'android')
            TipiLockModule.operateAudioSwitch(1, 1, this.normalizeLockData(lock), _callback)
        else {
            TipiLockModule.getLockAudioState(this.normalizeLockData(lock), _callback)
        }
    }

    static getElectricQuantity(lock, callback) {
        if (Platform.OS === 'android')
            TipiLockModule.getElectricQuantity(this.normalizeLockData(lock), this.normalizeCallback((res) => {
                if (res['electricQuantity']) {
                    // because we cant send long number trough bridge, we send it as a string
                    res.electricQuantity = Number(res['electricQuantity']);
                }
                callback && callback(res)
            }))
    }

    static setAudioState(isOn, lock, callback) {
        let _callback = this.normalizeCallback((info) => {
            let isOn = Platform.select({
                android: info.state === 1,
                ios: Boolean(info.isOn)
            });
            callback && callback({...info, isOn});
        })
        if (Platform.OS === 'android')
            TipiLockModule.operateAudioSwitch(2, isOn ? 1 : 0, this.normalizeLockData(lock), _callback)
        else {
            TipiLockModule.setLockAudioState(Boolean(isOn), this.normalizeLockData(lock), _callback)
        }
    }

    static connect(mac) {
        if (Platform.OS === 'android')
            TipiLockModule.connect(mac)
    }

    static addReceiveScanDeviceListener(callback) {
        if (Platform.OS === PlatformIOS) {
            listener = TipiLockIOSEmitter.addListener(iOSeceiverLockDeviceScanEvent, lockItemMap => {
                callback(lockItemMap)
            })
        } else {
            listener = DeviceEventEmitter.addListener(androidReceiverLockDeviceScanEvent, lockItemMap => {
                if (lockItemMap && lockItemMap['date']) {
                    lockItemMap['date'] = Number(lockItemMap['date'])
                }
                if (lockItemMap && lockItemMap['batteryCapacity']) {
                    lockItemMap['electricQuantity'] = Number(lockItemMap['batteryCapacity'])
                }
                callback(lockItemMap)
            })
        }
    }

    static removeReceiveScanDeviceListener() {
        if (listener != null) {
            listener.remove
        }
        listener = null;
    }

    static normalizeLockData(lockData) {
        try {
            if (__DEV__) {
                if (typeof lockData === 'string')
                    JSON.parse(lockData);
                else if (typeof lockData === 'object')
                    JSON.stringify(lockData);
                else {
                    throw new Error('Invalid lock data type (' + (typeof lockData) + ')')
                }
            }
            let obj = typeof lockData === 'string' ? JSON.parse(lockData) : lockData;
            if (typeof obj.lockVersion !== 'string') {
                obj.lockVersion = JSON.stringify(obj.lockVersion)
            }
            return JSON.stringify(obj);
        } catch (e) {
            throw new Error('Invalid lock data')
        }
    }

    static normalizeCallback(callback) {
        return (info) => {
            info.code = String(info.code || info.errorCode || '').trim().toLowerCase();
            info.message = info.message || info.errorMsg;
            if (Platform.OS === 'ios')
                info.message || this.iosMapErrorCodeToMessage[info.code] || info.message;
            if (info.code) {
                info.message += ` (${info.code})`
            }
            callback && callback(info)
        }
    }

    static iosMapErrorCodeToMessage = {
        //TTErrorHadReseted
        '0': 'The lock may have been reset',
        //TTErrorDataCRCError,
        '0x01': 'Error of CRC check',
        //TTErrorNoPermisston,
        '0x02': 'Failure of identity verification and no operation permissions',
        //TTErrorIsWrongPS,
        '0x03': 'Admin code is incorrect',
        //TTErrorNoMemory,
        '0x04': 'Lack of storage space',
        //TTErrorInSettingMode,
        '0x05': 'In setting mode',
        //TTErrorNoAdmin,
        '0x06': 'No administrator',
        //TTErrorIsNotSettingMode,
        '0x07': 'Not in setting mode',
        //TTErrorIsWrongDynamicPS,
        '0x08': 'Dynamic password error',
        //TTErrorIsNoPower,
        '0x0a': 'Battery without electricity',
        //TTErrorResetKeyboardPs,
        '0x0b': 'Setting 900 passwords failed',
        //TTErrorUpdateKeyboardIndex,
        '0x0c': 'Update the keyboard password sequence error',
        //TTErrorIsInvalidFlag,
        '0x0d': 'Invalid flag',
        //TTErrorEkeyOutOfDate,
        '0x0e': 'ekey expired',
        //TTErrorPasswordLengthInvalid,
        '0x0f': 'Invalid password length',
        //TTErrorSuperPasswordIsSameWithDeletePassword,
        '0x1': 'Admin Passcode is the same as Erase Passcode',
        //TTErrorEkeyNotToDate,
        '0x11': 'Short of validity',
        //TTErrorAesKey,
        '0x12': 'No login, no operation permissions',
        //TTErrorFail
        '0x13': 'operation failed',
        //TTErrorPsswordExist,
        '0x14': 'The added password has already existed',
        //TTErrorPasswordNotExist,
        '0x15': 'The password that are deleted or modified does not exist',
        //TTErrorNoFree_Memory,
        '0x16': 'Lack of storage space (as when adding a password)',
        //TTErrorInvalidParaLength,
        '0x17': 'Invalid parameter length',
        //TTErrorCardNotExist,
        '0x18': 'IC card does not exist',
        //TTErrorFingerprintDuplication,
        '0x19': 'Duplication of fingerprints',
        //TTErrorFingerprintNotExist,
        '0x1A': 'Fingerprints do not exist',
        //TTErrorInvalidCommand,
        '0x1B': 'Invalid Command',
        //TTErrorInFreezeMode,
        '0x1C': 'In Freeze Mode',
        //TTErrorInvalidClientPara,
        '0x1D': 'Invalid special string',
        //TTErrorLockIsLocked,
        '0x1E': 'Locked',
        //TTErrorRecordNotExist,
        '0x1F': 'Record not exist',
        //TTErrorNotSupportModifyPwd
        '0x60': 'Do not support the modification of the password',
        //TTErrorGetOperateLog,
        '0x61': 'Bluetooth disconnection',
    }
}
