package com.plugin.beacon_scanner

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel.EventSink

// Fixes: https://github.com/flutter/flutter/issues/34993
internal class MainThreadEventSink(private val eventSink: EventSink) : EventSink {
    private val handler: Handler = Handler(Looper.getMainLooper())

    override fun success(o: Any?) {
        handler.post { eventSink.success(o) }
    }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        handler.post { eventSink.error(errorCode, errorMessage, errorDetails) }
    }

    override fun endOfStream() {
        handler.post { eventSink.endOfStream() }
    }
}
