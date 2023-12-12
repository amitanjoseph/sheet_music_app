package com.example.sheet_music_app

import com.example.sheet_music_app.pigeon.ScannerAPI
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding

class MainActivity: FlutterActivity() {
    //Setup ffi for scanning
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ScannerAPI.setUp(flutterEngine.dartExecutor.binaryMessenger, Scanner(this))


    }
}
