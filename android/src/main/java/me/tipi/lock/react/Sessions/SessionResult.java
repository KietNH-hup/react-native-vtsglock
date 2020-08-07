package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.ttlock.bl.sdk.entity.Error;

public class SessionResult {
  private WritableMap arguments;

  public SessionResult(Error error) {
    arguments = Arguments.createMap();

    boolean success = error == Error.SUCCESS;
    arguments.putBoolean("success", success);
    if (!success) {
      arguments.putString("message", error.getDescription());
      arguments.putString("code", error.getErrorCode());
    }
  }

  public WritableMap arguments() {
    return arguments;
  }
}
