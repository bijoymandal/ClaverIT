package com.example.pro_dialer

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "com.nighatech.pro_dialer/native_call"
    private val TAG = "ProDialer"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "startCall") {

                    try {

                        val phoneNumber = call.argument<String>("phoneNumber")
                        val simSlot = call.argument<Int>("simSlot") ?: 0

                        Log.d(TAG, "PhoneNumber: $phoneNumber")
                        Log.d(TAG, "SimSlot: $simSlot")

                        if (phoneNumber.isNullOrBlank()) {
                            result.error("INVALID_NUMBER", "Phone number required", null)
                            return@setMethodCallHandler
                        }

                        val intent = Intent(Intent.ACTION_CALL)
                        intent.data = Uri.parse("tel:$phoneNumber")

                        // ✅ Select SIM slot
                        intent.putExtra("com.android.phone.extra.slot", simSlot)
                        intent.putExtra("slot", simSlot)
                        intent.putExtra("simSlot", simSlot)

                        startActivity(intent)

                        result.success(true)

                    } catch (e: Exception) {
                        Log.e(TAG, "Call error", e)
                        result.error("CALL_ERROR", e.message, null)
                    }

                } else {
                    result.notImplemented()
                }
            }
    }
}