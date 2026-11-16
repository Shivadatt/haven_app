package com.haven.child.usage

import android.content.Context
import android.content.ContextWrapper

/**
 * Lightweight test context wrapper for unit tests.
 */
class FakeTestContext(
    private val testPackageName: String = "com.haven.child",
) : ContextWrapper(null) {
    override fun getPackageName(): String = testPackageName
}
