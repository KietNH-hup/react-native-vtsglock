package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public class SetAdminKeyboardPasswordSession extends Session {

  private final String pin;

  public SetAdminKeyboardPasswordSession(String pin, String keyJson, Callback callback) {
    super(keyJson, callback);
    this.pin = pin;
  }

  @Override public void start() {
    getLockApi().connect(getLockData().getLockMac());
  }

  @Override public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
    getLockApi().setAdminKeyboardPassword(extendedBluetoothDevice, 0,
        getLockData().getLockVersion(), getLockData().getAdminPwd(), getLockData().getLockKey(),
        getLockData().getLockFlagPos(), getLockData().getAesKeyStr(), pin);
  }
}
