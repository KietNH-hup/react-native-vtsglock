type StatusInfoType<Data> = {
    success: false,
    code?: string,
    message?: string,
    errorMsg?: any,
    errorCode?: any
} |
    (Data & { success: true })

type SuccessErrorCallback<Data = {}> = (info: StatusInfoType<Data>) => void
type Callback<Info> = (info: Info) => void

type LockVersionObjectType = {
    showAdminKbpwdFlag: boolean
    groupId: number
    protocolVersion: number
    protocolType: number
    orgId: number
    logoUrl: string
    scene: number
}

type KeyObjectInfoType = {
    date: number
    specialValue: number
    lockAlias: string
    keyStatus: string
    endDate: number
    keyId: number
    lockMac: string
    timezoneRawOffset: number
    lockId: number
    electricQuantity: number
    lockFlagPos: number
    keyboardPwdVersion: number
    aesKeyStr: string
    remoteEnable: number
    lockVersion: LockVersionObjectType | string
    userType: string
    lockKey: string
    lockName: string
    startDate: number
    remarks: string
    keyRight: number
}

type TipiLockScanModel = {

    /**
     * Bluetooth mac address
     */
    lockMac: string

    /**
     * Bluetooth mac
     */
    lockName: string

    /**
     * Bluetooth signal strength
     */
    rssi: string

    /**
     *  Whether the lock is touched
     */
    isTouch: string

    /**
     * Can you add status
     */
    isSettingMode: boolean

    protocolType: string
    protocolVersion: string

    /**
     * timestamp / I dont sure what is it
     * android only
     */
    date?: number
    /**
     * may be -1
     */
    electricQuantity?: number
}

type LockData = string | object
export default class TipiLock {

    static init(): void

    /**
     * doesnt required. but call this may improve speed
     */
    static connect(mac: string): void

    static startDeviceScan(): void

    static stopDeviceScan(): void

    static setAdminKeyboardPassword(pin: string, lock: LockData, callback: SuccessErrorCallback): void

    static removeReceiveScanDeviceListener(): void

    static addReceiveScanDeviceListener(callback: Callback<TipiLockScanModel>): void

    static startBleService(): void

    static unlockByUser(lockItemObj: KeyObjectInfoType, callback: SuccessErrorCallback): void

    static unlockByAdministrator(lockItemObj: LockData, callback: SuccessErrorCallback): void

    static resetLock(lockData: LockData, callback: SuccessErrorCallback): void

    /**
     *
     * @param timestamp
     * @param timeZoneOffset set to -1 to keep current
     * @param lockData
     * @param callback
     */
    static setLockTime(timestamp: number, timeZoneOffset: number, lockData: LockData, callback: SuccessErrorCallback): void
                          
    static getLockTime(lockData: LockData, callback: SuccessErrorCallback): void

    static getElectricQuantity(lockItemObj: LockData, callback: SuccessErrorCallback<{ electricQuantity: number }>): void

    static resetKeyboardPassword(lockData: LockData, callback: SuccessErrorCallback<{}>): void

    static getAudioState(lock: LockData, callback: SuccessErrorCallback<{ battery?: number, isOn: boolean, operateType?: number }>): void

    static setAudioState(isOn: boolean, lock: LockData, callback: SuccessErrorCallback<{ battery?: number, isOn: boolean, operateType?: number }>): void

    static lockInitialize(lockMac: string, callback: Callback<{ lockDataJsonString: string, success: boolean, code?: string, message?: string }>): void

    static addPeriodKeyboardPassword(
        pin: string,
        startTimestamp: number,
        endTimestamp: number,
        lock: LockData,
        callback: SuccessErrorCallback<{}>
    ): void

    static modifyKeyboardPassword(
        oldPin: string,
        newPin: string,
        startTimestamp: number,
        endTimestamp: number,
        lock: LockData,
        callback: SuccessErrorCallback<{}>
    )

    static deleteOneKeyboardPassword(
        pin: string,
        lock: LockData,
        callback: SuccessErrorCallback<{}>
    )
}
