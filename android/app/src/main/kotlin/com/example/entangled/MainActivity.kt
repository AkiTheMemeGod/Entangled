package com.entangled.app

import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        enableHighRefreshRate()
    }

    private fun enableHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // API 30+: set a preferred display mode with the highest available refresh rate.
            val display = display ?: return
            val modes = display.supportedModes
            val highestRate = modes.maxByOrNull { it.refreshRate } ?: return
            val params = window.attributes
            params.preferredDisplayModeId = highestRate.modeId
            window.attributes = params
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // API 23-29: use the older preferredRefreshRate API.
            @Suppress("DEPRECATION")
            window.attributes = window.attributes.also { it.preferredRefreshRate = 120f }
        }
    }
}
