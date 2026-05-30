enum DownloadStatus { notDownloaded, downloading, paused, completed, failed }

class DownloadItem {
  final String id;
  final String title;
  final String subtitle;
  final String url;
  String? savePath;
  double progress;
  DownloadStatus status;
  int? totalSize; // in bytes
  String? lastError;

  DownloadItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.url,
    this.savePath,
    this.progress = 0.0,
    this.status = DownloadStatus.notDownloaded,
    this.totalSize,
    this.lastError,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'url': url,
      'savePath': savePath,
      'progress': progress,
      'status': status.index,
      'totalSize': totalSize,
      'lastError': lastError,
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      url: json['url'],
      savePath: json['savePath'],
      progress: (json['progress'] as num).toDouble(),
      status: DownloadStatus.values[json['status']],
      totalSize: json['totalSize'],
      lastError: json['lastError'],
    );
  }

  DownloadItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? url,
    String? savePath,
    double? progress,
    DownloadStatus? status,
    int? totalSize,
    String? lastError,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      url: url ?? this.url,
      savePath: savePath ?? this.savePath,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      totalSize: totalSize ?? this.totalSize,
      lastError: lastError ?? this.lastError,
    );
  }
}
