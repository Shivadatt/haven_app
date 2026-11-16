package com.haven.child.usage

import android.app.AppOpsManager
import com.haven.child.UsageContract
import org.junit.Assert.assertEquals
import org.junit.Test

class AppOpsPermissionReaderTest {

    private val context = FakeTestContext()
    private val fakeChecker = FakeAppOpsChecker()

    @Test
    fun testPermissionGrantedWhenModeAllowed() {
        fakeChecker.simulatedMode = AppOpsManager.MODE_ALLOWED
        val reader = AppOpsPermissionReader(checker = fakeChecker, apiLevel = 34)

        val status = reader.getPermissionStatus(context)
        assertEquals(UsageContract.PERMISSION_GRANTED, status)
    }

    @Test
    fun testPermissionDeniedWhenModeIgnored() {
        fakeChecker.simulatedMode = AppOpsManager.MODE_IGNORED
        val reader = AppOpsPermissionReader(checker = fakeChecker, apiLevel = 34)

        val status = reader.getPermissionStatus(context)
        assertEquals(UsageContract.PERMISSION_DENIED, status)
    }

    @Test
    fun testPermissionDeniedWhenModeDefault() {
        fakeChecker.simulatedMode = AppOpsManager.MODE_DEFAULT
        val reader = AppOpsPermissionReader(checker = fakeChecker, apiLevel = 34)

        val status = reader.getPermissionStatus(context)
        assertEquals(UsageContract.PERMISSION_DENIED, status)
    }

    @Test
    fun testPermissionUnsupportedWhenApiLessThanLollipop() {
        fakeChecker.simulatedMode = AppOpsManager.MODE_ALLOWED
        val reader = AppOpsPermissionReader(checker = fakeChecker, apiLevel = 19)

        val status = reader.getPermissionStatus(context)
        assertEquals(UsageContract.PERMISSION_UNSUPPORTED, status)
    }

    @Test
    fun testPermissionDeniedWhenCheckerThrowsException() {
        fakeChecker.shouldThrow = true
        val reader = AppOpsPermissionReader(checker = fakeChecker, apiLevel = 34)

        val status = reader.getPermissionStatus(context)
        assertEquals(UsageContract.PERMISSION_DENIED, status)
    }

    @Test
    fun testPermissionDeniedWhenContextIsNull() {
        val reader = AppOpsPermissionReader(checker = fakeChecker, apiLevel = 34)

        val status = reader.getPermissionStatus(null)
        assertEquals(UsageContract.PERMISSION_DENIED, status)
    }
}
