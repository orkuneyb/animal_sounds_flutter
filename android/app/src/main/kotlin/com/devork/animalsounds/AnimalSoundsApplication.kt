package com.devork.animalsounds

import android.app.Application
import android.content.Context
import android.util.Log
import org.json.JSONArray

/**
 * Guards the reminder cache of flutter_local_notifications.
 *
 * 1.3.0 shipped without ProGuard rules for the plugin and crashed whenever it
 * read this cache, including in the boot receiver, which runs before any
 * Flutter code. The rules fix the read; this class makes sure an entry the
 * plugin cannot reschedule (not a JSON array, or missing its id) never
 * reaches the receiver. A healthy cache is left untouched, and the Dart side
 * re-creates the reminders the parent enabled on the next app start.
 */
class AnimalSoundsApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        repairReminderCache(this)
    }

    companion object {
        private const val TAG = "AnimalSounds"
        private const val PREFS = "scheduled_notifications"
        private const val KEY = "scheduled_notifications"

        fun repairReminderCache(context: Context) {
            try {
                val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val json = prefs.getString(KEY, null) ?: return
                if (isReadable(json)) return
                prefs.edit().remove(KEY).apply()
                Log.w(TAG, "Dropped an unreadable reminder cache written by an older version")
            } catch (e: Exception) {
                Log.w(TAG, "Reminder cache check failed: ${e.message}")
            }
        }

        /** Every entry must be an object with the id the plugin reschedules by. */
        private fun isReadable(json: String): Boolean {
            return try {
                val list = JSONArray(json)
                (0 until list.length()).all { i -> list.getJSONObject(i).has("id") }
            } catch (e: Exception) {
                false
            }
        }
    }
}
