package dev.sonora.sonora.services

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * The "Sonora" Quick Settings tile: shows whether ambient listening is on and
 * toggles it.
 *
 * Android only lets a microphone service start while the app is visible, so
 * turning listening on goes through [StartListeningActivity], a brief
 * invisible activity. Turning it off stops the service directly.
 */
class ListeningTileService : TileService() {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val listener: (ServiceStateManager.Snapshot) -> Unit = { mainHandler.post(::refresh) }

    override fun onStartListening() {
        super.onStartListening()
        ServiceStateManager.addListener(listener)
        refresh()
    }

    override fun onStopListening() {
        ServiceStateManager.removeListener(listener)
        super.onStopListening()
    }

    override fun onClick() {
        super.onClick()
        if (ServiceStateManager.snapshot.listening) {
            SonoraRecognitionService.stop(this)
            return
        }
        // Starting the microphone needs an unlocked phone and a visible activity.
        if (isLocked) unlockAndRun(::openStartActivity) else openStartActivity()
    }

    private fun openStartActivity() {
        val intent = Intent(this, StartListeningActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT),
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun refresh() {
        val tile = qsTile ?: return
        val state = ServiceStateManager.snapshot
        tile.state = if (state.listening) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = "Sonora"
        val subtitle = if (state.listening) state.tileText() else "Off"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) tile.subtitle = subtitle
        tile.contentDescription = "Sonora ambient listening, $subtitle"
        tile.updateTile()
    }
}
