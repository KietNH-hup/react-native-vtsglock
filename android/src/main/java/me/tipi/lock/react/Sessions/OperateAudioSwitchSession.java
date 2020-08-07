package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public class OperateAudioSwitchSession extends Session {
  private final int operateType;
  private final int state;

  public OperateAudioSwitchSession(int operateType, int state, String keyJson, Callback callback) {
    super(keyJson, callback);

    this.operateType = operateType;
    this.state = state;
  }

  @Override public void start() {
    getLockApi().connect(getLockData().getLockMac());
  }

  @Override public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
    getLockApi().operateAudioSwitch(extendedBluetoothDevice, operateType, state, 0,
        getLockData().getLockVersion(), getLockData().getAdminPwd(), getLockData().getLockKey(),
        getLockData().getLockFlagPos(), getLockData().getAesKeyStr());
  }
}
