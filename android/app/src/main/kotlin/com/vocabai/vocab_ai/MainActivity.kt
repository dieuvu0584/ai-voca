package com.vocabai.vocab_ai

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BATTERY_CHANNEL = "com.vocabai/battery"
    private val ALARM_CHANNEL = "com.vocabai/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Battery optimization channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" -> {
                        result.success(isIgnoringBatteryOptimizations())
                    }
                    "requestIgnoreBatteryOptimization" -> {
                        requestIgnoreBatteryOptimization()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // Native alarm channel — dùng setAlarmClock (Samsung-proof)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAlarm" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val hour = call.argument<Int>("hour") ?: 9
                        val minute = call.argument<Int>("minute") ?: 0
                        val title = call.argument<String>("title") ?: "Đến lúc ôn từ vựng!"
                        val body = call.argument<String>("body") ?: "Hãy dành vài phút ôn bài nhé"
                        ReminderScheduler.schedule(this, id, hour, minute, title, body)
                        result.success(true)
                    }
                    "cancelAlarm" -> {
                        val id = call.argument<Int>("id")
                        if (id != null) {
                            ReminderScheduler.cancel(this, id)
                        } else {
                            ReminderScheduler.cancelAll(this)
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            return pm.isIgnoringBatteryOptimizations(packageName)
        }
        return true
    }

    private fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        }
    }
}
