package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public class LockInitializeSession extends Session {
  private ExtendedBluetoothDevice extendedBluetoothDevice;

  public LockInitializeSession(ExtendedBluetoothDevice extendedBluetoothDevice, Callback callback) {
    super(null, callback);

    this.extendedBluetoothDevice = extendedBluetoothDevice;
  }

  @Override public void start() {
    getLockApi().connect(extendedBluetoothDevice);
  }

  @Override public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
    getLockApi().lockInitialize(extendedBluetoothDevice);
  }
}
