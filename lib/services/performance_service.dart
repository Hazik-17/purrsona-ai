import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  static PerformanceService get instance => _instance;

  PerformanceService._internal() {
    _initializePlatformChannel();
  }

  static const platform = MethodChannel('com.myfyp.purrsona.performance');

  int _peakMemoryUsage = 0;
  DateTime _startTime = DateTime.now();
  Map<String, dynamic> _lastMemoryInfo = {};

  // Overlay visibility notifier
  final ValueNotifier<bool> isOverlayVisible = ValueNotifier(false);

  void _initializePlatformChannel() {
    platform.setMethodCallHandler((call) async {
          return null;
    });
  }

  /// Returns current memory usage from platform
  Future<int> getCurrentMemoryUsage() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final memoryInfo = await platform.invokeMethod('getMemoryUsage') as Map<dynamic, dynamic>;
        _lastMemoryInfo = Map<String, dynamic>.from(memoryInfo);

        // Use PSS (Proportional Set Size) as the most accurate measure of app memory usage
        final pssMemory = _lastMemoryInfo['pssMemory'] as int? ?? 0;

        if (pssMemory > _peakMemoryUsage) {
          _peakMemoryUsage = pssMemory;
        }

        return pssMemory;
      } else {
        // Fallback for other platforms (iOS, etc.)
        return _getSimulatedMemoryUsage();
      }
    } catch (e) {
      developer.log('Error getting memory usage: $e');
      return _getSimulatedMemoryUsage();
    }
  }

  /// Synchronous getter for backward compatibility (returns cached value)
  int get currentMemoryUsage {
    // Return last known value or fallback
    return _lastMemoryInfo['pssMemory'] as int? ?? _getSimulatedMemoryUsage();
  }

  /// Returns peak memory usage recorded during the session
  int get peakMemoryUsage => _peakMemoryUsage;

  /// Returns detailed memory information
  Map<String, dynamic> get memoryDetails => _lastMemoryInfo;

  /// Logs performance metric to console with context
  Future<void> logPerformanceMetric(String context) async {
    final current = await getCurrentMemoryUsage();
    final heapUsed = _lastMemoryInfo['heapUsed'] as int? ?? 0;
    final heapTotal = _lastMemoryInfo['heapTotal'] as int? ?? 0;
    final systemAvailable = _lastMemoryInfo['systemAvailable'] as int? ?? 0;

    developer.log('[$context] RAM: $current MB PSS (Heap: ${heapUsed}MB/${heapTotal}MB, System Available: ${systemAvailable}MB)');
  }

  /// Toggle overlay visibility
  void toggleOverlay(bool value) {
    isOverlayVisible.value = value;
  }

  /// Reset peak memory tracking
  void resetPeakMemory() {
    _peakMemoryUsage = 0;
    _startTime = DateTime.now();
    _lastMemoryInfo.clear();
  }

  /// Get simulated memory usage for fallback/debugging
  int _getSimulatedMemoryUsage() {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    final simulatedUsage = 50 + (elapsed * 2);
    if (simulatedUsage > _peakMemoryUsage) {
      _peakMemoryUsage = simulatedUsage;
    }
    return simulatedUsage;
  }
}