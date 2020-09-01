package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public class AddFingerPrint extends Session {
    
  public AddFingerPrint(String keyJson, Callback callback) {
    super(keyJson, callback);
  }

  @Override public void start() {
    getLockApi().connect(getLockData().getLockMac());
  }

  @Override public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
    getLockApi().addFingerPrint(extendedBluetoothDevice, 0,
        getLockData().getLockVersion(), getLockData().getAdminPwd(), getLockData().getLockKey(),
        getLockData().getLockFlagPos(), getLockData().getAesKeyStr());
  }
}
