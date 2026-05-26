enum DownloadStatus { pending, downloading, paused, completed, failed }

class DownloadItem {
  final String id; // surah index or reciter id
  final String title;
  final String subtitle;
  final DownloadStatus status;
  final double progress;
  final String size;
  final String? filePath;

  const DownloadItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    required this.size,
    this.filePath,
  });

  DownloadItem copyWith({
    DownloadStatus? status,
    double? progress,
    String? filePath,
  }) => DownloadItem(
    id: id,
    title: title,
    subtitle: subtitle,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    size: size,
    filePath: filePath ?? this.filePath,
  );
}

class StorageInfo {
  final double totalSizeGB;
  final double usedSizeGB;
  final double appSizeGB;

  const StorageInfo({
    required this.totalSizeGB,
    required this.usedSizeGB,
    required this.appSizeGB,
  });

  double get freeSizeGB => totalSizeGB - usedSizeGB;
  double get appPercentage => appSizeGB / totalSizeGB;
}
