package me.tipi.lock.react.Sessions;

import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public interface ExecutableSession {

  public void start();
  public void execute(ExtendedBluetoothDevice extendedBluetoothDevice);

}
