import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_style.dart';
import '../models/reciter.dart';
import '../services/offline_reciter_service.dart';

class ReciterDialog extends StatefulWidget {
  final Reciter currentReciter;
  final int surah;
  final ValueChanged<Reciter> onSelect;

  const ReciterDialog({
    super.key,
    required this.currentReciter,
    required this.surah,
    required this.onSelect,
  });

  @override
  State<ReciterDialog> createState() => _ReciterDialogState();
}

class _ReciterDialogState extends State<ReciterDialog> {
  final _reciterService = OfflineReciterService();
  late final Future<List<Reciter>> _reciters;

  @override
  void initState() {
    super.initState();
    _reciters = _reciterService.getRecitersForSurah(widget.surah);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.pageBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Pilih Qari (Syekh)',
                style: AppTextStyle.quranSurahNameStyle(
                  fontSize: 18,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Audio katalog lengkap diputar per surat',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: AppColors.gold.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Reciter>>(
                  future: _reciters,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reciters = snapshot.data!;
                    if (reciters.isEmpty) {
                      return const Center(
                        child: Text('Belum ada audio untuk surat ini'),
                      );
                    }

                    return ListView.separated(
                      itemCount: reciters.length,
                      separatorBuilder:
                          (_, _) => Divider(
                            color: Colors.grey.withValues(alpha: 0.14),
                            height: 1,
                          ),
                      itemBuilder: (context, index) {
                        final reciter = reciters[index];
                        final isSelected =
                            reciter.id == widget.currentReciter.id;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.gold.withValues(
                              alpha: isSelected ? 1 : 0.12,
                            ),
                            child: Text(
                              reciter.name[0],
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : AppColors.gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            reciter.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? AppColors.gold : textColor,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            reciter.collectionName ?? 'Audio per surat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          trailing:
                              isSelected
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.gold,
                                    size: 18,
                                  )
                                  : const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                          onTap: () {
                            widget.onSelect(reciter);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
