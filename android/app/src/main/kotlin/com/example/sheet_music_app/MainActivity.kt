package com.example.sheet_music_app

import com.example.sheet_music_app.pigeon.ScannerAPI
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    //Setup ffi for scanning
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ScannerAPI.setUp(flutterEngine.dartExecutor.binaryMessenger, Scanner())
    }
}
