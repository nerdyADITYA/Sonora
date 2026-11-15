package dev.sonora.sonora.services

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import dev.sonora.sonora.MainActivity
import dev.sonora.sonora.privacy.PrivacyConsent

/**
 * Invisible activity the Quick Settings tile opens to start listening.
 * Android 14+ only lets a microphone foreground service start while the app
 * is visible; this activity is, for a moment. Without consent to the privacy
 * disclosure or microphone permission it opens the app, which asks for both.
 */
class StartListeningActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val allowed = PrivacyConsent.isAccepted(this) &&
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        if (allowed) {
            try {
                SonoraRecognitionService.start(this)
            } catch (e: Exception) {
                Log.e(TAG, "Could not start listening from the tile", e)
            }
        } else {
            startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
        finish()
    }

    private companion object {
        const val TAG = "SonoraTile"
    }
}
