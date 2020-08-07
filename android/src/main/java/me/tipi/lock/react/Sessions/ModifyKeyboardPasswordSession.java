package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public class ModifyKeyboardPasswordSession extends Session {
  private final String oldPin;
  private final String newPin;
  private final long startTimestamp;
  private final long endTimestamp;

  public ModifyKeyboardPasswordSession(String oldPin, String newPin, long startTimestamp,
      long endTimestamp, String keyJson, Callback callback) {
    super(keyJson, callback);
    this.oldPin = oldPin;
    this.newPin = newPin;
    this.startTimestamp = startTimestamp;
    this.endTimestamp = endTimestamp;
  }

  @Override public void start() {
    getLockApi().connect(getLockData().getLockMac());
  }

  @Override public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
    getLockApi().modifyKeyboardPassword(extendedBluetoothDevice, 0, getLockData().getLockVersion(),
        getLockData().getAdminPwd(), getLockData().getLockKey(), getLockData().getLockFlagPos(), 2,
        oldPin, newPin, startTimestamp, endTimestamp, getLockData().getAesKeyStr(),
        getLockData().getTimezoneRawOffset());
  }
}
