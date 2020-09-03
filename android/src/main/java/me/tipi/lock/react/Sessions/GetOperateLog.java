package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public class GetOperateLog extends Session {

  public GetOperateLog(String keyJson, Callback callback) {
    super(keyJson, callback);
  }

  @Override public void start() {
    getLockApi().connect(getLockData().getLockMac());
  }

  @Override public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
    getLockApi().getOperateLog(extendedBluetoothDevice, getLockData().getLockVersion(),
        getLockData().getAesKeyStr(), getLockData().getTimezoneRawOffset());
  }
}
