package me.tipi.lock.react;

import com.ttlock.bl.sdk.entity.LockData;

public class ExtendedLockData extends LockData {
    public long startDate = 0;
    public long endDate = 0;

    public void setStartDate(long startDate) {
        this.startDate = startDate;
    }

    public long getStartDate() {
        return startDate;
    }

    public void setEndDate(long endDate) {
        this.endDate = endDate;
    }

    public long getEndDate() {
        return endDate;
    }
}
