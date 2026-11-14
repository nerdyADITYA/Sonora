package dev.sonora.sonora.services

import android.content.Context
import java.util.Calendar

/** Counts recognition requests per local day so ambient listening can't run up ACRCloud costs. */
class RequestBudget(context: Context, private val dailyLimit: Int = ListeningPolicy.DAILY_REQUEST_BUDGET) {

    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    val limit: Int get() = dailyLimit

    @Synchronized
    fun usedToday(): Int {
        rollOver()
        return prefs.getInt(KEY_COUNT, 0)
    }

    @Synchronized
    fun hasRemaining(): Boolean = usedToday() < dailyLimit

    @Synchronized
    fun record() {
        rollOver()
        prefs.edit().putInt(KEY_COUNT, prefs.getInt(KEY_COUNT, 0) + 1).apply()
    }

    private fun rollOver() {
        val now = Calendar.getInstance()
        val today = "${now.get(Calendar.YEAR)}-${now.get(Calendar.DAY_OF_YEAR)}"
        if (prefs.getString(KEY_DAY, null) != today) {
            prefs.edit().putString(KEY_DAY, today).putInt(KEY_COUNT, 0).apply()
        }
    }

    private companion object {
        const val PREFS = "sonora_request_budget"
        const val KEY_DAY = "day"
        const val KEY_COUNT = "count"
    }
}
