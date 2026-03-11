package com.example.pro_dialer

import android.content.Intent
import android.net.Uri
import android.telephony.SubscriptionManager
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

                when (call.method) {

                    // ✅ CALL FUNCTION
                    "startCall" -> {
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

                            // SIM slot selection
                            intent.putExtra("com.android.phone.extra.slot", simSlot)
                            intent.putExtra("slot", simSlot)
                            intent.putExtra("simSlot", simSlot)

                            startActivity(intent)

                            result.success(true)

                        } catch (e: Exception) {
                            Log.e(TAG, "Call error", e)
                            result.error("CALL_ERROR", e.message, null)
                        }
                    }

                    // ✅ GET SIM PROVIDERS
                    "getSimProviders" -> {
    try {

        val manager =
            getSystemService(TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager

        val simNames = mutableListOf<String>()

        val subscriptions = manager.activeSubscriptionInfoList

        if (!subscriptions.isNullOrEmpty()) {
            for (info in subscriptions) {

                val displayName = info.displayName?.toString()
                val carrierName = info.carrierName?.toString()

                val name = when {
                    !displayName.isNullOrBlank() -> displayName
                    !carrierName.isNullOrBlank() -> carrierName
                    else -> "SIM ${info.simSlotIndex + 1}"
                }

                simNames.add(name)
            }
        }

        result.success(simNames)

    } catch (e: Exception) {
        Log.e(TAG, "SIM error", e)
        result.error("SIM_ERROR", e.message, null)
    }
}

                    else -> result.notImplemented()
                }
            }
    }
}