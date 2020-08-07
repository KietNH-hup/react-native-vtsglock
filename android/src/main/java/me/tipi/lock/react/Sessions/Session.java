package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.ttlock.bl.sdk.api.TTLockAPI;

import java.lang.reflect.Type;

import me.tipi.lock.react.ExtendedLockData;

public abstract class Session implements ExecutableSession{
  private final ExtendedLockData lockData;
  private final Callback callback;
  public TTLockAPI lockApi;

  public Session(String lockJson, Callback callback) {
    this.callback = callback;

    Type lockDataType = new TypeToken<ExtendedLockData>() {
    }.getType();
    this.lockData = new Gson().fromJson(lockJson, lockDataType);
  }

  public ExtendedLockData getLockData() {
    return lockData;
  }

  public Callback getCallback() {
    return callback;
  }

  public void setLockApi(TTLockAPI lockApi) {
    this.lockApi = lockApi;
  }

  public TTLockAPI getLockApi() {
    return lockApi;
  }
}
