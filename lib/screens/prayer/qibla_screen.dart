import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/prayer_location_model.dart';
import '../../services/prayer_location_service.dart';
import '../../services/qibla_service.dart';
import '../../widgets/prayer/qibla_compass_widget.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final _locationService = PrayerLocationService();
  final _qiblaService = QiblaService();

  PrayerLocation _location = PrayerLocation.defaultLocation;
  QiblaInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final location = await _locationService.loadLocation();
    final info = _qiblaService.calculate(location);
    if (!mounted) return;
    setState(() {
      _location = location;
      _info = info;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Arah Qiblat')),
      body:
          _loading || info == null
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
              : ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B1B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _location.displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'INDONESIA',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.52),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        QiblaCompassWidget(
                          qiblaDirection: info.directionDegrees,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Qiblat ${_degrees(info.directionDegrees)} dari Utara',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.goldLt,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jarak ke Ka\'bah ± ${info.distanceKm.round()} KM',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.goldLt,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Jauhkan perangkat dari objek berbahan besi atau logam agar lebih akurat.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.74),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  String _degrees(double value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')}°';
  }
}
