package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public class ResetLockSession extends Session {

  public ResetLockSession(String keyJson, Callback callback) {
    super(keyJson, callback);
  }

  @Override public void start() {
    getLockApi().connect(getLockData().getLockMac());
  }

  @Override public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
    getLockApi().resetLock(extendedBluetoothDevice, 0, getLockData().getLockVersion(),
        getLockData().getAdminPwd(), getLockData().getLockKey(), getLockData().getLockFlagPos(),
        getLockData().getAesKeyStr());
  }
}
