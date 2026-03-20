package com.example.autotally_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.autotally/sms_receiver"
        )

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                SmsBroadcastReceiver.smsCallback = { sender, body, timestamp ->
                    runOnUiThread {
                        eventSink?.success(mapOf(
                            "sender" to sender,
                            "body" to body,
                            "timestamp" to timestamp
                        ))
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                SmsBroadcastReceiver.smsCallback = null
            }
        })
    }
}
