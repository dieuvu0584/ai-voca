package com.vocabai.vocab_ai

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "vocab_alarm_v3"
        const val CHANNEL_NAME = "Nhắc học từ vựng"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("alarm_id", 0)
        val title = intent.getStringExtra("title") ?: "Đến lúc ôn từ vựng!"
        val body = intent.getStringExtra("body") ?: "Hãy dành vài phút ôn bài nhé"

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Tạo/cập nhật channel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val audioAttr = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Nhắc nhở học từ vựng hàng ngày"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 200, 300)
                setSound(soundUri, audioAttr)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            nm.createNotificationChannel(channel)
        }

        // Intent mở app khi tap notification
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val iconResId = context.resources.getIdentifier(
            "ic_launcher", "mipmap", context.packageName
        )
        val safeIcon = if (iconResId != 0) iconResId else android.R.drawable.ic_popup_reminder

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(safeIcon)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            builder.setSound(soundUri)
            builder.setVibrate(longArrayOf(0, 300, 200, 300))
        }

        nm.notify(1000 + alarmId, builder.build())

        // Phát âm thủ công (Samsung có thể ignore channel sound)
        try {
            val ringtone = RingtoneManager.getRingtone(
                context,
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            )
            ringtone?.play()
        } catch (_: Exception) {}

        // Re-schedule cho ngày hôm sau
        ReminderScheduler.rescheduleNextDay(context, alarmId)
    }
}
