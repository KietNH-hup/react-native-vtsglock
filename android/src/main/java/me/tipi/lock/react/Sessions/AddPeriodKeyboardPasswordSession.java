package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public class AddPeriodKeyboardPasswordSession extends Session {
  private final String pin;
  private final long startTimestamp;
  private final long endTimestamp;

  public AddPeriodKeyboardPasswordSession(String pin, long startTimestamp, long endTimestamp,
      String keyJson, Callback callback) {
    super(keyJson, callback);
    this.pin = pin;
    this.startTimestamp = startTimestamp;
    this.endTimestamp = endTimestamp;
  }

  @Override public void start() {
    getLockApi().connect(getLockData().getLockMac());
  }

  @Override public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
    getLockApi().addPeriodKeyboardPassword(extendedBluetoothDevice, 0,
        getLockData().getLockVersion(), getLockData().getAdminPwd(), getLockData().getLockKey(),
        getLockData().getLockFlagPos(), pin, startTimestamp, endTimestamp,
        getLockData().getAesKeyStr(), getLockData().getTimezoneRawOffset());
  }
}
