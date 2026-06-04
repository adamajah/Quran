package com.example.flutter_quran_app

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AdhanAlarmScheduler.CHANNEL_NAME
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAdhanAlarm" -> {
                    val id = call.argument<Int>("id")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis")
                    if (id == null || title == null || body == null || triggerAtMillis == null) {
                        result.error("bad_args", "Missing adhan alarm arguments", null)
                        return@setMethodCallHandler
                    }
                    AdhanAlarmScheduler.schedule(
                        context = this,
                        id = id,
                        title = title,
                        body = body,
                        triggerAtMillis = triggerAtMillis
                    )
                    result.success(true)
                }

                "cancelAdhanAlarm" -> {
                    val id = call.argument<Int>("id")
                    if (id == null) {
                        result.error("bad_args", "Missing adhan alarm id", null)
                        return@setMethodCallHandler
                    }
                    AdhanAlarmScheduler.cancel(this, id)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}
