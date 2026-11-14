package dev.sonora.sonora.recognition

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities

/**
 * Sonora recognises songs online only (offline recognition was deferred; see
 * docs/RECOGNITION_FEASIBILITY.md). Checking first means the microphone isn't
 * opened, and no request is counted, when a match can't succeed anyway.
 */
object Connectivity {

    /** True when the active network has working internet (validated by Android). */
    fun isOnline(context: Context): Boolean {
        val manager = context.getSystemService(ConnectivityManager::class.java) ?: return true
        val capabilities = manager.getNetworkCapabilities(manager.activeNetwork) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
            capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }

    const val OFFLINE_MESSAGE = "No internet connection. Sonora needs one to identify songs."
}
