package com.example.right_craft_media_os

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs

class OverlayActivity : FlutterActivity() {
    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun getDartEntrypointFunctionName(): String {
        return "overlayMain"
    }
}
