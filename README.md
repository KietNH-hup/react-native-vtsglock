
# react-native-tipilock

## Getting started

Install package

```bash
$ yarn add https://gitlab.com/yooki/yooki-mobile/react-native-tipilock.git
```

Link it to your project

```bash
$ react-native link react-native-tipilock
```

### Config your project

## ios

## Android
config android/build.gradle:
```bash
buildscript {
    ext {
        // Change min sdk to 18
        minSdkVersion = 18
    }
}

allprojects {
    repositories {
        ...    
        // Add below lines
        flatDir{
            dirs "$rootDir/../node_modules/react-native-tipilock/android/libs"
        }
    }
}
```  

do this step if you get android merger error: 
```bash
<manifest
    ...
	xmlns:tools="http://schemas.android.com/tools"
	>
	...
	<application
	    ...
	    tools:replace="android:allowBackup"
	>
```
	
## Usage

### Import
`import TipiLockModule from 'react-native-tipilock';`

### Init
`TipiLockModule.init()` init TipiLock SDK, this must be call before using other methods

### Scan nearby locks
`TipiLockModule.addReceiveScanDeviceListener(callback)` add listener to receive bluetooth lock before do start device scan

`TipiLockModule.removeReceiveScanDeviceListener()` remove listener

`TipiLockModule.startDeviceScan()` start scan bluetooth locks

`TipiLockModule.stopDeviceScan()` start scan bluetooth locks

### Init lock
`TipiLockModule.lockInitialize(lockMac, callback)` start lock initialization

### Unlock
`TipiLockModule.unlockByAdministrator(lock, callback)` unlock lock by using admin key

`TipiLockModule.unlockByUser(lock, callback)` unlock lock by using e-key

### Adjust time
`TipiLockModule.setLockTime(timestamp, lock, callback)` change lock's time

`TipiLockModule.getLockTime(lock, callback)` get lock's current time

### Change admin pin
`TipiLockModule.setAdminKeyboardPassword(pin, lock, callback)`

### Manage temporary pins
`TipiLockModule.addPeriodKeyboardPassword(pin, startTimestamp, endTimestamp, lock, callback)` add new temporary pin

`TipiLockModule.modifyKeyboardPassword(oldPin, newPin, startTimestamp, endTimestamp, lock, callback)` modify an existing pin

`TipiLockModule.deleteOneKeyboardPassword(pin, lock, callback)` delete one pin

`TipiLockModule.resetKeyboardPassword(lock, callback)` delete all pins

### Change audio state
`TipiLockModule.getAudioState(lock, callback)`

`TipiLockModule.setAudioState(state, lock, callback)`

### Reset lock
`TipiLockModule.resetLock(lock, callback)` reset lock, when this operation return success, the lock can be init again.


### Log
`TipiLockModule.getOperateLog(lock, callback)` get log from lock 


#change logs

# 1.1.2
* apply real start/end date to unlock method of android module
