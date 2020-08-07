package me.tipi.lock.react.Sessions;

import android.util.Log;

import com.facebook.react.bridge.Callback;
import com.ttlock.bl.sdk.command.CommandUtil;
import com.ttlock.bl.sdk.entity.TransferData;
import com.ttlock.bl.sdk.scanner.ExtendedBluetoothDevice;
import com.ttlock.bl.sdk.util.DigitUtil;

import me.tipi.lock.react.ExtendedLockData;

public class UnlockByUserSession extends Session {

    public UnlockByUserSession(String keyJson, Callback callback) {
        super(keyJson, callback);
    }

    @Override
    public void start() {
        ExtendedLockData lockData = getLockData();
        if (getLockApi().isConnected(lockData.getLockMac())) {
            this.unlockByUser(
                    0,
                    lockData.getLockVersion(),
                    lockData.getStartDate(),
                    lockData.getEndDate(),
                    lockData.getLockKey(),
                    lockData.getLockFlagPos(),
                    lockData.getAesKeyStr(),
                    lockData.getTimezoneRawOffset()
            );
        } else {
            getLockApi().connect(lockData.getLockMac());
        }
    }

    @Override
    public void execute(ExtendedBluetoothDevice extendedBluetoothDevice) {
        ExtendedLockData lockData = getLockData();
        getLockApi().unlockByUser(
                extendedBluetoothDevice,
                0,
                lockData.getLockVersion(),
                lockData.getStartDate(),
                lockData.getEndDate(),
                lockData.getLockKey(),
                lockData.getLockFlagPos(),
                lockData.getAesKeyStr(),
                lockData.getTimezoneRawOffset()
        );
    }

    private void unlockByUser(int uid, String lockVersion, long startDate, long endDate, String unlockKey, int lockFlagPos, String aesKeyStr, long timezoneOffset) {
        byte[] aesKeyArray = null;
        if (aesKeyStr != null && !"".equals(aesKeyStr)) {
            aesKeyArray = DigitUtil.convertAesKeyStrToBytes(aesKeyStr);
        }

        TransferData transferData = new TransferData();
        transferData.setAPICommand(4);
        transferData.setCommand((byte) 85);
        transferData.setmUid(uid);
        transferData.setLockVersion(lockVersion);
        transferData.setStartDate(startDate);
        transferData.setEndDate(endDate);
        transferData.setUnlockKey(unlockKey);
        transferData.setLockFlagPos(lockFlagPos);
        transferData.setTimezoneOffSet(timezoneOffset);
        TransferData.setAesKeyArray(aesKeyArray);
        CommandUtil.U_checkUserTime(transferData);
    }
}
