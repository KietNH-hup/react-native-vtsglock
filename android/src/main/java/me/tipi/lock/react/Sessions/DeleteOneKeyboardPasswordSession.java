package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public class DeleteOneKeyboardPasswordSession extends Session {

  private final String pin;

  public DeleteOneKeyboardPasswordSession(String pin, String keyJson, Callback callback) {
    super(keyJson, callback);
    this.pin = pin;
  }

  @Override public void start() {
    getLockApi().connect(getLockData().getLockMac());
  }

  @Override public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
    getLockApi().deleteOneKeyboardPassword(extendedBluetoothDevice, 0,
        getLockData().getLockVersion(), getLockData().getAdminPwd(), getLockData().getLockKey(),
        getLockData().getLockFlagPos(), 3, pin, getLockData().getAesKeyStr());
  }
}
