    package com.example.pro_dialer

    import android.content.Context
    import android.content.Intent
    import android.net.Uri
    import android.os.Bundle
    import android.util.Log
    import androidx.annotation.NonNull
    import io.flutter.embedding.android.FlutterActivity
    import io.flutter.embedding.engine.FlutterEngine
    import io.flutter.plugin.common.MethodChannel

    class MainActivity : FlutterActivity() {
        private val CHANNEL = "com.nighatech.pro_dialer/native_call"
        private val TAG = "ProDialer"
        
        private var methodChannel: MethodChannel? = null

        override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
            super.configureFlutterEngine(flutterEngine)
            
            // ✅ EXISTING CALL CHANNEL
            methodChannel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            methodChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startCall" -> {
                        try {
                            Log.d(TAG, "startCall invoked")
                            Log.d(TAG, "Raw arguments: ${call.arguments}")

                            val phoneNumber = call.argument<String>("phoneNumber")

                            Log.d(TAG, "Extracted phoneNumber: $phoneNumber")

                            if (phoneNumber.isNullOrBlank()) {
                                result.error("INVALID_NUMBER", "Phone number is required", null)
                                return@setMethodCallHandler
                            }

                            // 🔴 CHECK CALL_PHONE PERMISSION
                            if (checkSelfPermission(android.Manifest.permission.CALL_PHONE)
                                != android.content.pm.PackageManager.PERMISSION_GRANTED) {

                                Log.e(TAG, "CALL_PHONE permission not granted")
                                result.error("PERMISSION_DENIED", "CALL_PHONE permission not granted", null)
                                return@setMethodCallHandler
                            }

                            // Use Intent.ACTION_CALL to let the system (or default dialer) handle the UI
                            val intent = Intent(Intent.ACTION_CALL)
                            intent.data = Uri.parse("tel:$phoneNumber")
                            
                            try {
                                startActivity(intent)
                                Log.d(TAG, "Started call via Intent.ACTION_CALL")
                                result.success(true)
                            } catch (e: Exception) {
                                Log.e(TAG, "Error starting call activity", e)
                                result.error("ACTIVITY_ERROR", "Failed to start call activity: ${e.message}", null)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error starting call", e)
                            result.error("CALL_ERROR", "Failed to start call: ${e.message}", null)
                        }
                    }
                    
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }
