import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../../constants/app_colors.dart';

class QiblaCompassWidget extends StatefulWidget {
  final double qiblaDirection;

  const QiblaCompassWidget({super.key, required this.qiblaDirection});

  @override
  State<QiblaCompassWidget> createState() => _QiblaCompassWidgetState();
}

class _QiblaCompassWidgetState extends State<QiblaCompassWidget> {
  Stream<CompassEvent>? _compassEvents;
  bool _checkingAccess = true;
  bool _canReadCompass = false;
  bool _canOpenSettings = false;
  String? _accessMessage;

  @override
  void initState() {
    super.initState();
    _prepareCompass();
  }

  Future<void> _prepareCompass({bool requestPermission = true}) async {
    final stream = FlutterCompass.events;
    if (stream == null) {
      _setCompassAccess(
        canReadCompass: false,
        message: 'Sensor kompas tidak tersedia di perangkat ini.',
      );
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      _setCompassAccess(
        canReadCompass: false,
        canOpenSettings: true,
        message: 'Aktifkan layanan lokasi agar arah kompas bisa dibaca.',
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      _setCompassAccess(
        canReadCompass: false,
        message: 'Izinkan lokasi agar kompas bisa bergerak realtime.',
      );
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _setCompassAccess(
        canReadCompass: false,
        canOpenSettings: true,
        message:
            'Izin lokasi ditolak permanen. Aktifkan dari pengaturan aplikasi.',
      );
      return;
    }

    _setCompassAccess(canReadCompass: true, stream: stream);
  }

  void _setCompassAccess({
    required bool canReadCompass,
    Stream<CompassEvent>? stream,
    bool canOpenSettings = false,
    String? message,
  }) {
    if (!mounted) return;
    setState(() {
      _checkingAccess = false;
      _canReadCompass = canReadCompass;
      _canOpenSettings = canOpenSettings;
      _accessMessage = message;
      _compassEvents = stream;
    });
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
    await _prepareCompass(requestPermission: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) {
      return _CompassWithMessage(
        qiblaDirection: widget.qiblaDirection,
        message: 'Menyiapkan sensor kompas...',
      );
    }

    if (!_canReadCompass) {
      return _CompassWithMessage(
        qiblaDirection: widget.qiblaDirection,
        message: _accessMessage ?? 'Kompas belum bisa dibaca.',
        actionLabel: _canOpenSettings ? 'Buka Pengaturan' : 'Coba Lagi',
        onAction:
            _canOpenSettings
                ? _openSettings
                : () => _prepareCompass(requestPermission: true),
      );
    }

    final stream = _compassEvents;
    if (stream == null) {
      return _CompassWithMessage(
        qiblaDirection: widget.qiblaDirection,
        message: 'Sensor kompas tidak tersedia di perangkat ini.',
      );
    }

    return StreamBuilder<CompassEvent>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _CompassWithMessage(
            qiblaDirection: widget.qiblaDirection,
            message: 'Gagal membaca sensor kompas.',
            actionLabel: 'Coba Lagi',
            onAction: () => _prepareCompass(requestPermission: false),
          );
        }

        final heading = snapshot.data?.heading;
        if (heading == null) {
          final isWaiting =
              snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData;
          return _CompassWithMessage(
            qiblaDirection: widget.qiblaDirection,
            message:
                isWaiting
                    ? 'Menunggu data kompas...'
                    : 'Perangkat ini tidak mengirim data sensor kompas.',
          );
        }

        final normalizedHeading = _normalizeDegrees(heading);
        final qiblaRotation = _normalizeDegrees(
          widget.qiblaDirection - normalizedHeading,
        );
        return _CompassFace(
          dialRotationDegrees: -normalizedHeading,
          qiblaRotationDegrees: qiblaRotation,
          headingDegrees: normalizedHeading,
          isLive: true,
        );
      },
    );
  }

  double _normalizeDegrees(double value) => (value % 360 + 360) % 360;
}

class _CompassFace extends StatelessWidget {
  final double dialRotationDegrees;
  final double qiblaRotationDegrees;
  final double? headingDegrees;
  final bool isLive;

  const _CompassFace({
    required this.qiblaRotationDegrees,
    this.dialRotationDegrees = 0,
    this.headingDegrees,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _AnimatedCompassRotation(
            degrees: dialRotationDegrees,
            child: CustomPaint(
              size: const Size.square(280),
              painter: _CompassPainter(),
            ),
          ),
          Positioned(
            top: 8,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withValues(alpha: 0.78),
              size: 28,
            ),
          ),
          _AnimatedCompassRotation(
            degrees: qiblaRotationDegrees,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.navigation_rounded,
                  size: 96,
                  color: AppColors.goldLt,
                ),
                Container(
                  width: 4,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 28,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                headingDegrees == null
                    ? 'Kompas'
                    : '${headingDegrees!.round()}°',
                key: ValueKey(headingDegrees?.round()),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isLive ? 0.82 : 0.48),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCompassRotation extends StatefulWidget {
  final double degrees;
  final Widget child;

  const _AnimatedCompassRotation({required this.degrees, required this.child});

  @override
  State<_AnimatedCompassRotation> createState() =>
      _AnimatedCompassRotationState();
}

class _AnimatedCompassRotationState extends State<_AnimatedCompassRotation> {
  late double _turns;

  @override
  void initState() {
    super.initState();
    _turns = _degreesToTurns(widget.degrees);
  }

  @override
  void didUpdateWidget(covariant _AnimatedCompassRotation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetTurns = _degreesToTurns(widget.degrees);
    _turns += _shortestDeltaTurns(_turns, targetTurns);
  }

  double _degreesToTurns(double degrees) => degrees / 360;

  double _shortestDeltaTurns(double currentTurns, double targetTurns) {
    return ((targetTurns - currentTurns + 0.5) % 1) - 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: _turns,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: widget.child,
    );
  }
}

class _CompassWithMessage extends StatelessWidget {
  final double qiblaDirection;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CompassWithMessage({
    required this.qiblaDirection,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.46,
              child: _CompassFace(qiblaRotationDegrees: qiblaDirection),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.26),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.explore_off_rounded,
                    color: AppColors.goldLt,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.32,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(actionLabel!),
            style: TextButton.styleFrom(foregroundColor: AppColors.goldLt),
          ),
        ],
      ],
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;

    final fill =
        Paint()
          ..color = const Color(0xFF202020)
          ..style = PaintingStyle.fill;
    final border =
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;
    final tick =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 1.1;

    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, border);
    canvas.drawCircle(center, radius * 0.72, border);

    for (var i = 0; i < 60; i++) {
      final angle = i * 6 * math.pi / 180;
      final isMajor = i % 5 == 0;
      final outer = Offset(
        center.dx + math.sin(angle) * radius,
        center.dy - math.cos(angle) * radius,
      );
      final innerRadius = radius - (isMajor ? 15 : 8);
      final inner = Offset(
        center.dx + math.sin(angle) * innerRadius,
        center.dy - math.cos(angle) * innerRadius,
      );
      canvas.drawLine(inner, outer, tick..strokeWidth = isMajor ? 1.6 : 0.8);
    }

    _drawLabel(canvas, center, radius, 'N', 0);
    _drawLabel(canvas, center, radius, 'E', 90);
    _drawLabel(canvas, center, radius, 'S', 180);
    _drawLabel(canvas, center, radius, 'W', 270);
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    String label,
    double degrees,
  ) {
    final angle = degrees * math.pi / 180;
    final position = Offset(
      center.dx + math.sin(angle) * (radius - 34),
      center.dy - math.cos(angle) * (radius - 34),
    );
    final paragraph = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: label == 'N' ? AppColors.goldLt : Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    paragraph.paint(
      canvas,
      position - Offset(paragraph.width / 2, paragraph.height / 2),
    );
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) => false;
}
