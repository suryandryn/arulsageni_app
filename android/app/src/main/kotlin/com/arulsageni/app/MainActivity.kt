package com.arulsageni.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        buatSaluranNotifikasi()
    }

    /**
     * Saluran push FCM berprioritas tinggi agar notifikasi muncul sebagai popup (heads-up).
     * Tingkat saluran tidak bisa diubah setelah dibuat, jadi saluran bawaan FCM
     * (fcm_fallback_notification_channel, tingkat default tanpa popup) dihapus.
     * Id harus sama dengan default_notification_channel_id di manifest & channel_id dari server.
     */
    private fun buatSaluranNotifikasi() {
        val nm = getSystemService(NotificationManager::class.java) ?: return
        nm.createNotificationChannel(
            NotificationChannel(SALURAN, "Pemberitahuan", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "Jadwal berobat, pengingat, dan pesan dari admin"
            },
        )
        nm.deleteNotificationChannel("fcm_fallback_notification_channel")
    }

    companion object {
        const val SALURAN = "pemberitahuan"
    }
}
