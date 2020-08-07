package me.tipi.lock.react;

import com.ttlock.bl.sdk.api.TTLockAPI;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;
import me.tipi.lock.react.Sessions.Session;
import me.tipi.lock.react.Sessions.SessionResult;

class TipiLockSession {
  private TTLockAPI lockApi;
  private Session session;

  void setLockApi(TTLockAPI lockApi) {
    this.lockApi = lockApi;
  }

  void start(Session session) {
    if (lockApi != null) {
      session.setLockApi(lockApi);
      this.session = session;

      session.start();
    }
  }

  void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
    if (lockApi != null && session != null) {
      session.execute(extendedBluetoothDevice);
    }
  }

  void setResult(ExtendedBluetoothDevice extendedBluetoothDevice, SessionResult result) {
    if (session != null && session.getCallback() != null) {
      session.getCallback().invoke(result.arguments());
      session = null;
    }
  }
}
