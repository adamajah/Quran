import 'dart:async';

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
  bool _updatingLocation = false;
  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requestId = ++_loadRequestId;
    final savedLocation = await _locationService.loadLocation();
    final info = _qiblaService.calculate(savedLocation);
    if (!mounted || requestId != _loadRequestId) return;
    setState(() {
      _location = savedLocation;
      _info = info;
      _loading = false;
    });

    if (savedLocation.automatic) {
      unawaited(_refreshAutomaticLocation(requestId));
    }
  }

  Future<void> _refreshAutomaticLocation(int requestId) async {
    final result = await _locationService.useCurrentLocation();
    final info = _qiblaService.calculate(result.location);
    if (!mounted || requestId != _loadRequestId) return;
    setState(() {
      _location = result.location;
      _info = info;
      _loading = false;
    });
    if (result.message != null) _snack(result.message!);
  }

  Future<void> _useCurrentLocation() async {
    if (_updatingLocation) return;
    setState(() => _updatingLocation = true);
    final result = await _locationService.useCurrentLocation();
    final info = _qiblaService.calculate(result.location);
    if (!mounted) return;
    setState(() {
      _location = result.location;
      _info = info;
      _updatingLocation = false;
      _loading = false;
    });
    _snack(result.message ?? 'Lokasi perangkat aktif.');
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? AppColors.dark;
    final mutedText = textColor.withValues(alpha: isDark ? 0.68 : 0.60);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Arah Qiblat'),
        actions: [
          IconButton(
            tooltip: 'Gunakan lokasi saat ini',
            icon:
                _updatingLocation
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.goldLt,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.my_location_rounded),
            onPressed: _updatingLocation ? null : _useCurrentLocation,
          ),
        ],
      ),
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
                      color: theme.cardColor,
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
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _location.automatic
                              ? 'LOKASI PERANGKAT AKTIF'
                              : _location.country.toUpperCase(),
                          style: TextStyle(
                            color: mutedText,
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
                          style: TextStyle(color: mutedText, fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _updatingLocation ? null : _useCurrentLocation,
                            icon:
                                _updatingLocation
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.my_location_rounded,
                                      size: 18,
                                    ),
                            label: Text(
                              _updatingLocation
                                  ? 'Mengambil lokasi...'
                                  : 'Gunakan Lokasi Saat Ini',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.goldLt,
                              side: BorderSide(
                                color: AppColors.gold.withValues(alpha: 0.42),
                              ),
                            ),
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
                              color: textColor.withValues(
                                alpha: isDark ? 0.74 : 0.68,
                              ),
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

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
