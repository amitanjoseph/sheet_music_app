package com.example.sheet_music_app

import com.example.sheet_music_app.pigeon.ScannerAPI

//ScannerAPI implementation
class Scanner : ScannerAPI {
    override fun message(): String {
        return "Hello, Flutter!"
    }
}