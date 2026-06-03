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
    final isLocked = qiblaRotationDegrees <= 3 || qiblaRotationDegrees >= 357;
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
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isLocked ? 1 : 0.52,
              child: Icon(
                isLocked
                    ? Icons.lock_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: isLocked ? AppColors.goldLt : Colors.white70,
                size: isLocked ? 22 : 28,
              ),
            ),
          ),
          _AnimatedCompassRotation(
            degrees: qiblaRotationDegrees,
            child: SizedBox.square(
              dimension: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(top: 6, child: _KaabaTargetIcon(locked: isLocked)),
                  Positioned(
                    top: 52,
                    child: Container(
                      width: 4,
                      height: 82,
                      decoration: BoxDecoration(
                        color:
                            isLocked
                                ? AppColors.goldLt
                                : AppColors.gold.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.24),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 122,
                    child: Icon(
                      Icons.navigation_rounded,
                      size: 38,
                      color:
                          isLocked
                              ? AppColors.goldLt
                              : Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 50,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isLocked ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.goldLt.withValues(alpha: 0.62),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 11,
                      color: AppColors.goldLt,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ka\'bah terkunci',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 62,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isLocked ? 0.92 : 0.32,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isLocked
                            ? AppColors.goldLt
                            : Colors.white.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  size: 17,
                  color: isLocked ? AppColors.goldLt : Colors.white70,
                ),
              ),
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

class _KaabaTargetIcon extends StatelessWidget {
  final bool locked;

  const _KaabaTargetIcon({required this.locked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            locked
                ? AppColors.gold.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.34),
        border: Border.all(
          color:
              locked
                  ? AppColors.goldLt
                  : AppColors.gold.withValues(alpha: 0.55),
          width: locked ? 1.8 : 1.1,
        ),
        boxShadow: [
          if (locked)
            BoxShadow(
              color: AppColors.goldLt.withValues(alpha: 0.22),
              blurRadius: 14,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CustomPaint(size: Size.square(34), painter: _KaabaPainter()),
          if (locked)
            const Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.lock_rounded, size: 12, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _KaabaPainter extends CustomPainter {
  const _KaabaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.22,
      size.width * 0.64,
      size.height * 0.58,
    );
    final shadow =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.shift(const Offset(1, 2)),
        const Radius.circular(2),
      ),
      shadow,
    );

    final black = Paint()..color = const Color(0xFF111111);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(2)),
      black,
    );

    final side =
        Path()
          ..moveTo(body.right, body.top)
          ..lineTo(size.width * 0.90, size.height * 0.32)
          ..lineTo(size.width * 0.90, size.height * 0.85)
          ..lineTo(body.right, body.bottom)
          ..close();
    canvas.drawPath(side, Paint()..color = const Color(0xFF252525));

    final top =
        Path()
          ..moveTo(body.left, body.top)
          ..lineTo(body.right, body.top)
          ..lineTo(size.width * 0.90, size.height * 0.32)
          ..lineTo(size.width * 0.30, size.height * 0.12)
          ..close();
    canvas.drawPath(top, Paint()..color = const Color(0xFF2F2A21));

    final gold = Paint()..color = AppColors.goldLt;
    canvas.drawRect(
      Rect.fromLTWH(body.left, body.top + body.height * 0.22, body.width, 3),
      gold,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        body.left + body.width * 0.58,
        body.top + body.height * 0.36,
        4,
        body.height * 0.42,
      ),
      Paint()..color = AppColors.gold.withValues(alpha: 0.88),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
