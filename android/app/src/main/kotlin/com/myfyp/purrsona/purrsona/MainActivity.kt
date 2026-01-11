package com.myfyp.purrsona.purrsona

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.myfyp.purrsona.performance"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMemoryUsage" -> {
                    try {
                        val memoryInfo = getMemoryUsage()
                        result.success(memoryInfo)
                    } catch (e: Exception) {
                        result.error("MEMORY_ERROR", "Failed to get memory usage", e.message)
                    }
                }
                "getPeakMemoryUsage" -> {
                    try {
                        val peakMemory = getPeakMemoryUsage()
                        result.success(peakMemory)
                    } catch (e: Exception) {
                        result.error("PEAK_MEMORY_ERROR", "Failed to get peak memory usage", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getMemoryUsage(): Map<String, Any> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)

        val runtime = Runtime.getRuntime()
        val usedMemory = (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024) // MB
        val totalMemory = runtime.totalMemory() / (1024 * 1024) // MB
        val maxMemory = runtime.maxMemory() / (1024 * 1024) // MB

        // Get PSS (Proportional Set Size) for this process
        val pssMemory = Debug.getPss() / 1024 // KB to MB

        return mapOf(
            "heapUsed" to usedMemory.toInt(),
            "heapTotal" to totalMemory.toInt(),
            "heapMax" to maxMemory.toInt(),
            "pssMemory" to pssMemory,
            "systemAvailable" to (memoryInfo.availMem / (1024 * 1024)).toInt(),
            "systemTotal" to (memoryInfo.totalMem / (1024 * 1024)).toInt(),
            "systemLow" to memoryInfo.lowMemory
        )
    }

    private fun getPeakMemoryUsage(): Int {
        val runtime = Runtime.getRuntime()
        // Peak memory is approximated by max memory usage seen
        // In a real implementation, you'd track this over time
        return (runtime.totalMemory() / (1024 * 1024)).toInt()
    }
}