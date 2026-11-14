package dev.sonora.sonora.bridge

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/** Streams native events to Flutter on [BridgeContract.EVENTS_CHANNEL]. */
class SonoraEventChannel(messenger: BinaryMessenger) : EventChannel.StreamHandler {

    private val channel = EventChannel(messenger, BridgeContract.EVENTS_CHANNEL)

    fun register() = channel.setStreamHandler(this)

    fun unregister() {
        channel.setStreamHandler(null)
        SonoraEvents.detach()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        SonoraEvents.attach(events)
        SonoraEvents.emit(BridgeContract.Events.BRIDGE_CONNECTED)
    }

    override fun onCancel(arguments: Any?) = SonoraEvents.detach()
}

/**
 * Process-wide publisher for native events.
 *
 * Native components (later: the recognition service) call [emit] without knowing
 * whether Flutter is attached. With no listener the event is dropped. Durable
 * state, such as recognition history, belongs in the database, not here.
 */
object SonoraEvents {
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var sink: EventChannel.EventSink? = null

    fun attach(sink: EventChannel.EventSink) {
        this.sink = sink
    }

    fun detach() {
        sink = null
    }

    fun emit(type: String, data: Map<String, Any?>? = null) {
        val event = mapOf(
            "type" to type,
            "timestamp" to System.currentTimeMillis(),
            "data" to data,
        )
        // EventSink must be used on the platform (main) thread.
        mainHandler.post { sink?.success(event) }
    }
}
