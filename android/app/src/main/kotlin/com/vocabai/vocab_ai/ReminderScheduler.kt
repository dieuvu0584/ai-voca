package com.vocabai.vocab_ai

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Hỗ trợ nhiều alarm độc lập, mỗi alarm có ID riêng.
 * Dùng AlarmManager.setAlarmClock() — Samsung OneUI không block được.
 */
object ReminderScheduler {
    private const val PREFS_NAME = "vocab_reminder_prefs"
    private const val KEY_ENABLED = "reminder_enabled"
    private const val KEY_IDS = "reminder_ids" // danh sách id, phân cách bằng ","

    fun schedule(context: Context, id: Int, hour: Int, minute: Int, title: String, body: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Lưu thông tin alarm
        val ids = getIds(prefs).toMutableSet().also { it.add(id) }
        prefs.edit()
            .putBoolean(KEY_ENABLED, true)
            .putString(KEY_IDS, ids.joinToString(","))
            .putInt("alarm_${id}_hour", hour)
            .putInt("alarm_${id}_minute", minute)
            .putString("alarm_${id}_title", title)
            .putString("alarm_${id}_body", body)
            .apply()

        scheduleAlarm(context, id, hour, minute, title, body)
    }

    fun cancel(context: Context, id: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ids = getIds(prefs).toMutableSet().also { it.remove(id) }
        val editor = prefs.edit()
            .putString(KEY_IDS, ids.joinToString(","))
            .remove("alarm_${id}_hour")
            .remove("alarm_${id}_minute")
            .remove("alarm_${id}_title")
            .remove("alarm_${id}_body")
        if (ids.isEmpty()) editor.putBoolean(KEY_ENABLED, false)
        editor.apply()

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(createAlarmIntent(context, id, "", ""))
    }

    fun cancelAll(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val ids = getIds(prefs)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (id in ids) {
            alarmManager.cancel(createAlarmIntent(context, id, "", ""))
        }
        prefs.edit().putBoolean(KEY_ENABLED, false).putString(KEY_IDS, "").apply()
    }

    fun rescheduleNextDay(context: Context, id: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean(KEY_ENABLED, false)
        if (!enabled) return
        if (!getIds(prefs).contains(id)) return

        val hour = prefs.getInt("alarm_${id}_hour", 9)
        val minute = prefs.getInt("alarm_${id}_minute", 0)
        val title = prefs.getString("alarm_${id}_title", "Đến lúc ôn từ vựng!") ?: "Đến lúc ôn từ vựng!"
        val body = prefs.getString("alarm_${id}_body", "Hãy dành vài phút ôn bài nhé") ?: "Hãy dành vài phút ôn bài nhé"

        scheduleAlarm(context, id, hour, minute, title, body)
    }

    private fun scheduleAlarm(context: Context, id: Int, hour: Int, minute: Int, title: String, body: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val now = System.currentTimeMillis()
        val calendar = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.HOUR_OF_DAY, hour)
            set(java.util.Calendar.MINUTE, minute)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        if (calendar.timeInMillis <= now) {
            calendar.add(java.util.Calendar.DAY_OF_YEAR, 1)
        }

        val triggerTime = calendar.timeInMillis
        val intent = createAlarmIntent(context, id, title, body)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val showIntent = PendingIntent.getActivity(
                context, id,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(triggerTime, showIntent),
                intent
            )
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTime, intent)
        }
    }

    private fun createAlarmIntent(context: Context, id: Int, title: String, body: String): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("alarm_id", id)
            putExtra("title", title)
            putExtra("body", body)
        }
        return PendingIntent.getBroadcast(
            context, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun getIds(prefs: android.content.SharedPreferences): Set<Int> {
        val str = prefs.getString(KEY_IDS, "") ?: ""
        return str.split(",").mapNotNull { it.trim().toIntOrNull() }.toSet()
    }
}
