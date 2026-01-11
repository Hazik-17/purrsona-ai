import 'dart:async';
import 'package:flutter/material.dart';
import '../services/performance_service.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;

  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  int _currentRam = 0;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _startMemoryUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startMemoryUpdates() {
    // Update memory usage every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final ram = await PerformanceService.instance.getCurrentMemoryUsage();
      if (mounted) {
        setState(() {
          _currentRam = ram;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PerformanceService.instance.isOverlayVisible,
      builder: (context, isVisible, child) {
        return Stack(
          children: [
            widget.child,
            if (isVisible) _buildDebugInfo(),
          ],
        );
      },
    );
  }

  Widget _buildDebugInfo() {
    return Positioned(
      top: 40,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(
          'RAM: $_currentRam MB',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}