package me.tipi.lock.react.Sessions;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;

public class SetLockTimeSession extends Session {
    private long timestamp;
    private long timeZoneOffset;

    public SetLockTimeSession(long timestamp, long timeZoneOffset, String keyJson, Callback callback) {
        super(keyJson, callback);

        this.timestamp = timestamp;
        this.timeZoneOffset = timeZoneOffset;
    }

    @Override
    public void start() {
        getLockApi().connect(getLockData().getLockMac());
    }

    @Override
    public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
        getLockApi().setLockTime(extendedBluetoothDevice, 0, getLockData().getLockVersion(),
                getLockData().getLockKey(), timestamp, getLockData().getLockFlagPos(),
                getLockData().getAesKeyStr(),
                this.timeZoneOffset == -1 ? getLockData().getTimezoneRawOffset() : this.timeZoneOffset
        );
    }
}
