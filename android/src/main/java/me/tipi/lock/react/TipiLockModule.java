package me.tipi.lock.react;

import android.app.Activity;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.gson.Gson;
import com.ttlock.bl.sdk.api.TTLockAPI;
import com.ttlock.bl.sdk.callback.TTLockCallback;
import com.ttlock.bl.sdk.entity.DeviceInfo;
import com.ttlock.bl.sdk.entity.Error;
import com.ttlock.bl.sdk.entity.LockData;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;
import com.ttlock.bl.sdk.util.LogUtil;

import java.text.DateFormat;
import java.util.HashMap;

import me.tipi.lock.react.Sessions.AddPeriodKeyboardPasswordSession;
import me.tipi.lock.react.Sessions.DeleteOneKeyboardPasswordSession;
import me.tipi.lock.react.Sessions.GetElectricQuantitySession;
import me.tipi.lock.react.Sessions.GetLockTimeSession;
import me.tipi.lock.react.Sessions.LockInitializeSession;
import me.tipi.lock.react.Sessions.ModifyKeyboardPasswordSession;
import me.tipi.lock.react.Sessions.OperateAudioSwitchSession;
import me.tipi.lock.react.Sessions.ResetKeyboardPasswordSession;
import me.tipi.lock.react.Sessions.ResetLockSession;
import me.tipi.lock.react.Sessions.SessionResult;
import me.tipi.lock.react.Sessions.SetAdminKeyboardPasswordSession;
import me.tipi.lock.react.Sessions.SetLockTimeSession;
import me.tipi.lock.react.Sessions.UnlockByAdministratorSession;
import me.tipi.lock.react.Sessions.UnlockByUserSession;

public class TipiLockModule extends ReactContextBaseJavaModule implements TTLockCallback {
    private final static String RECEIVER_BT_SCAN_DEVICE_EVENT = "ScanLockDeviceEvent";

    private ReactApplicationContext reactContext;
    private TTLockAPI lockApi;
    private TipiLockSession session;
    private HashMap<String, ExtendedBluetoothDevice> cachedDevices = new HashMap<>();

    public TipiLockModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        this.session = new TipiLockSession();
    }

    @Override
    public String getName() {
        return "TipiLockModule";
    }

    @ReactMethod
    public void init() {
        lockApi = new TTLockAPI(reactContext.getApplicationContext(), this);
        session.setLockApi(lockApi);
    }

    @ReactMethod
    public void startBleService() {
        Activity currentActivity = getCurrentActivity();
        if (currentActivity != null) lockApi.startBleService(currentActivity);
    }

    @ReactMethod
    public void connect(String mac) {
        Activity currentActivity = getCurrentActivity();
        if (currentActivity != null) {
            if (this.lockApi != null) {
                if (this.lockApi.isBLEEnabled(currentActivity)) {
                    if (!this.lockApi.isConnected(mac))
                        this.lockApi.connect(mac);
                }
            }
        }
    }

    @ReactMethod
    public void disconnect() {
        if (this.lockApi != null) {
            this.lockApi.disconnect();
        }
    }

    @ReactMethod
    public void stopBleService() {
        Activity currentActivity = getCurrentActivity();
        if (currentActivity != null) lockApi.stopBleService(getCurrentActivity());
    }

    @ReactMethod
    public void startDeviceScan() {
        cachedDevices.clear();
        lockApi.startBTDeviceScan();
    }

    @ReactMethod
    public void stopDeviceScan() {
        lockApi.stopBTDeviceScan();
    }

    @ReactMethod
    public void lockInitialize(String lockMac, Callback callback) {
        ExtendedBluetoothDevice extendedBluetoothDevice = cachedDevices.get(lockMac);
        if (extendedBluetoothDevice != null) {
            session.start(new LockInitializeSession(extendedBluetoothDevice, callback));
        }
    }

    @ReactMethod
    public void setLockTime(double timestamp, double timeZoneOffset, String keyJson, Callback callback) {
        session.start(new SetLockTimeSession((long) timestamp, (long) timeZoneOffset ,keyJson, callback));
    }

    @ReactMethod
    public void getLockTime(String keyJson, Callback callback) {
        session.start(new GetLockTimeSession(keyJson, callback));
    }

    @ReactMethod
    public void resetLock(String keyJson, Callback callback) {
        session.start(new ResetLockSession(keyJson, callback));
    }

    @ReactMethod
    public void unlockByAdministrator(String keyJson, Callback callback) {
        session.start(new UnlockByAdministratorSession(keyJson, callback));
    }

    @ReactMethod
    public void unlockByUser(String keyJson, Callback callback) {
        session.start(new UnlockByUserSession(keyJson, callback));
    }

    @ReactMethod
    public void getElectricQuantity(String keyJson, Callback callback) {
        session.start(new GetElectricQuantitySession(keyJson, callback));
    }

    @ReactMethod
    public void addPeriodKeyboardPassword(String pin, double startTimestamp, double endTimestamp,
                                          String keyJson, Callback callback) {
        session.start(
                new AddPeriodKeyboardPasswordSession(pin, (long) startTimestamp, (long) endTimestamp,
                        keyJson, callback));
    }

    @ReactMethod
    public void modifyKeyboardPassword(String oldPin, String newPin, double startTimestamp,
                                       double endTimestamp, String keyJson, Callback callback) {
        session.start(new ModifyKeyboardPasswordSession(oldPin, newPin, (long) startTimestamp,
                (long) endTimestamp, keyJson, callback));
    }

    @ReactMethod
    public void deleteOneKeyboardPassword(String pin, String keyJson, Callback callback) {
        session.start(new DeleteOneKeyboardPasswordSession(pin, keyJson, callback));
    }

    @ReactMethod
    public void resetKeyboardPassword(String keyJson, Callback callback) {
        session.start(new ResetKeyboardPasswordSession(keyJson, callback));
    }

    @ReactMethod
    public void setAdminKeyboardPassword(String pin, String keyJson, Callback callback) {
        session.start(new SetAdminKeyboardPasswordSession(pin, keyJson, callback));
    }

    @ReactMethod
    public void operateAudioSwitch(int operateType, int state, String keyJson, Callback callback) {
        session.start(new OperateAudioSwitchSession(operateType, state, keyJson, callback));
    }

    @Override
    public void onFoundDevice(ExtendedBluetoothDevice extendedBluetoothDevice) {
        String name = extendedBluetoothDevice.getName();
        ExtendedBluetoothDevice needAddDevice = cacheAndFilterScanDevice(extendedBluetoothDevice);
        if (needAddDevice != null) {
            WritableMap map = Arguments.createMap();
            map.putString("lockName", name);
            map.putString("lockMac", extendedBluetoothDevice.getAddress());
            map.putBoolean("isSettingMode", extendedBluetoothDevice.isSettingMode());
            map.putInt("rssi", extendedBluetoothDevice.getRssi());
            map.putBoolean("isTouch", extendedBluetoothDevice.isTouch());
            map.putInt("batteryCapacity", extendedBluetoothDevice.getBatteryCapacity());
            map.putString("date", extendedBluetoothDevice.getDate() + "");
            getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit(RECEIVER_BT_SCAN_DEVICE_EVENT, map);
        }
    }

    private ExtendedBluetoothDevice cacheAndFilterScanDevice(ExtendedBluetoothDevice btDevice) {
        ExtendedBluetoothDevice newAddDevice = btDevice;
        String lockMac = btDevice.getAddress();
        if (cachedDevices.isEmpty()) {
            cachedDevices.put(lockMac, btDevice);
        } else {
            ExtendedBluetoothDevice child = cachedDevices.get(lockMac);
            if (child == null) {
                cachedDevices.put(lockMac, btDevice);
            } else {
                if (newAddDevice.isSettingMode() != child.isSettingMode()) {
                    cachedDevices.remove(lockMac);
                    cachedDevices.put(lockMac, btDevice);
                } else {
                    newAddDevice = null;
                }
            }
        }

        return newAddDevice;
    }

    @Override
    public void onDeviceConnected(ExtendedBluetoothDevice extendedBluetoothDevice) {
        session.execute(extendedBluetoothDevice);
    }

    @Override
    public void onDeviceDisconnected(ExtendedBluetoothDevice extendedBluetoothDevice) {
    /*if (callback != null) {
      WritableMap map = Arguments.createMap();
      map.putBoolean("success", false);
      //map.putString("errorCode", ERROR_CODE_TIME_OUT);
      if (lockOperation != NONE) {
        callback.invoke(map);
      }
      callback = null;
    }*/
    }

    @Override
    public void onLockInitialize(ExtendedBluetoothDevice extendedBluetoothDevice, LockData lockData,
                                 Error error) {
        SessionResult result = new SessionResult(error);
        result.arguments().putString("lockDataJsonString", new Gson().toJson(lockData));

        session.setResult(extendedBluetoothDevice, result);
    }

    @Override
    public void onSetLockTime(ExtendedBluetoothDevice extendedBluetoothDevice, Error error) {
        session.setResult(extendedBluetoothDevice, new SessionResult(error));
    }

    @Override
    public void onResetLock(ExtendedBluetoothDevice extendedBluetoothDevice, Error error) {
        session.setResult(extendedBluetoothDevice, new SessionResult(error));
    }

    @Override
    public void onUnlock(ExtendedBluetoothDevice extendedBluetoothDevice, int uid, int uniqueid, long lockTime, Error error) {
        session.setResult(extendedBluetoothDevice, new SessionResult(error));
    }

    @Override
    public void onGetOperateLog(ExtendedBluetoothDevice extendedBluetoothDevice, String lockLog,
                                Error error) {
        SessionResult result = new SessionResult(error);
        result.arguments().putString("lockOperateLog", lockLog);
        session.setResult(extendedBluetoothDevice, result);
    }

    @Override
    public void onSetAdminKeyboardPassword(ExtendedBluetoothDevice extendedBluetoothDevice, String s,
                                           Error error) {
        session.setResult(extendedBluetoothDevice, new SessionResult(error));
    }

    @Override
    public void onGetLockTime(ExtendedBluetoothDevice extendedBluetoothDevice, long timestamp,
                              Error error) {
        SessionResult result = new SessionResult(error);
        result.arguments().putDouble("timestamp", (double) timestamp);
        session.setResult(extendedBluetoothDevice, result);
    }

    @Override
    public void onAddKeyboardPassword(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                      String s, long l, long l1, Error error) {
        session.setResult(extendedBluetoothDevice, new SessionResult(error));
    }

    @Override
    public void onModifyKeyboardPassword(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                         String s, String s1, Error error) {
        session.setResult(extendedBluetoothDevice, new SessionResult(error));
    }

    @Override
    public void onDeleteOneKeyboardPassword(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                            String s, Error error) {
        session.setResult(extendedBluetoothDevice, new SessionResult(error));
    }

    @Override
    public void onOperateAudioSwitch(ExtendedBluetoothDevice extendedBluetoothDevice, int battery,
                                     int operateType, int state, Error error) {
        SessionResult result = new SessionResult(error);
        result.arguments().putDouble("operateType", operateType);
        result.arguments().putDouble("state", state);
        result.arguments().putDouble("battery", battery);
        session.setResult(extendedBluetoothDevice, result);
    }

    @Override
    public void onResetKeyboardPassword(ExtendedBluetoothDevice extendedBluetoothDevice, String s,
                                        long l, Error error) {
        session.setResult(extendedBluetoothDevice, new SessionResult(error));
    }


    //UNUSED
    @Override
    public void onResetEKey(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                            Error error) {

    }

    @Override
    public void onSetLockName(ExtendedBluetoothDevice extendedBluetoothDevice, String s,
                              Error error) {

    }

    @Override
    public void onSetDeletePassword(ExtendedBluetoothDevice extendedBluetoothDevice, String s,
                                    Error error) {

    }

    @Override
    public void onSetMaxNumberOfKeyboardPassword(ExtendedBluetoothDevice extendedBluetoothDevice,
                                                 int i, Error error) {

    }

    @Override
    public void onResetKeyboardPasswordProgress(ExtendedBluetoothDevice extendedBluetoothDevice,
                                                int i, Error error) {

    }

    @Override
    public void onDeleteAllKeyboardPassword(ExtendedBluetoothDevice extendedBluetoothDevice,
                                            Error error) {

    }

    @Override
    public void onSearchDeviceFeature(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1,
                                      Error error) {

    }

    @Override
    public void onGetLockVersion(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1,
                                 int i2, int i3, int i4, Error error) {

    }

    @Override
    public void onAddICCard(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1, long l,
                            Error error) {

    }

    @Override
    public void onModifyICCardPeriod(ExtendedBluetoothDevice extendedBluetoothDevice, int i, long l,
                                     long l1, long l2, Error error) {

    }

    @Override
    public void onDeleteICCard(ExtendedBluetoothDevice extendedBluetoothDevice, int i, long l,
                               Error error) {

    }

    @Override
    public void onClearICCard(ExtendedBluetoothDevice extendedBluetoothDevice, int i, Error error) {

    }

    @Override
    public void onSetWristbandKeyToLock(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                        Error error) {

    }

    @Override
    public void onSetWristbandKeyToDev(Error error) {

    }

    @Override
    public void onSetWristbandKeyRssi(Error error) {

    }

    @Override
    public void onAddFingerPrint(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1,
                                 long l, Error error) {

    }

    @Override
    public void onAddFingerPrint(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1,
                                 long l, int i2, Error error) {

    }

    @Override
    public void onFingerPrintCollection(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                        Error error) {

    }

    @Override
    public void onFingerPrintCollection(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                        int i1, int i2, Error error) {

    }

    @Override
    public void onModifyFingerPrintPeriod(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                          long l, long l1, long l2, Error error) {

    }

    @Override
    public void onDeleteFingerPrint(ExtendedBluetoothDevice extendedBluetoothDevice, int i, long l,
                                    Error error) {

    }

    @Override
    public void onClearFingerPrint(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                   Error error) {

    }

    @Override
    public void onSearchAutoLockTime(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1,
                                     int i2, int i3, Error error) {

    }

    @Override
    public void onModifyAutoLockTime(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1,
                                     Error error) {

    }

    @Override
    public void onReadDeviceInfo(ExtendedBluetoothDevice extendedBluetoothDevice,
                                 DeviceInfo deviceInfo, Error error) {

    }

    @Override
    public void onEnterDFUMode(ExtendedBluetoothDevice extendedBluetoothDevice, Error error) {

    }

    @Override
    public void onGetLockSwitchState(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1,
                                     Error error) {

    }

    @Override
    public void onLock(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1, int i2, long l,
                       Error error) {

    }

    @Override
    public void onScreenPasscodeOperate(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                        int i1, Error error) {

    }

    @Override
    public void onRecoveryData(ExtendedBluetoothDevice extendedBluetoothDevice, int i, Error error) {

    }

    @Override
    public void onSearchICCard(ExtendedBluetoothDevice extendedBluetoothDevice, int i, String s,
                               Error error) {

    }

    @Override
    public void onSearchFingerPrint(ExtendedBluetoothDevice extendedBluetoothDevice, int i, String s,
                                    Error error) {

    }

    @Override
    public void onSearchPasscode(ExtendedBluetoothDevice extendedBluetoothDevice, String s,
                                 Error error) {

    }

    @Override
    public void onSearchPasscodeParam(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                      String s, long l, Error error) {

    }

    @Override
    public void onOperateRemoteUnlockSwitch(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                            int i1, int i2, int i3, Error error) {

    }

    @Override
    public void onGetElectricQuantity(ExtendedBluetoothDevice extendedBluetoothDevice, int electricQuantity,
                                      Error error) {
        SessionResult result = new SessionResult(error);
        result.arguments().putString("electricQuantity", electricQuantity + "");
        session.setResult(extendedBluetoothDevice, result);
    }

    @Override
    public void onOperateRemoteControl(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1,
                                       int i2, Error error) {

    }

    @Override
    public void onOperateDoorSensorLocking(ExtendedBluetoothDevice extendedBluetoothDevice, int i,
                                           int i1, int i2, Error error) {

    }

    @Override
    public void onGetDoorSensorState(ExtendedBluetoothDevice extendedBluetoothDevice, int i, int i1,
                                     Error error) {

    }

    @Override
    public void onSetNBServer(ExtendedBluetoothDevice extendedBluetoothDevice, int i, Error error) {

    }
}
