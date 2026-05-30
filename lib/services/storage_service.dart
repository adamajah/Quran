import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:storage_space/storage_space.dart';

class StorageService {
  Future<String> getDownloadPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/downloads';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  Future<String?> resolveDownloadFilePath(String savedPath) async {
    final fileName = savedPath.split(Platform.pathSeparator).last;
    final currentPath = '${await getDownloadPath()}/$fileName';
    final file = File(currentPath);
    if (!await file.exists() || await file.length() == 0) return null;
    return currentPath;
  }

  Future<StorageSpace?> getStorageInfo() async {
    try {
      return await getStorageSpace(
        lowOnSpaceThreshold: 2 * 1024 * 1024 * 1024, // 2GB
        fractionDigits: 1,
      );
    } catch (e) {
      return null;
    }
  }

  Future<double> getAppUsageSize() async {
    try {
      final downloadDir = await getDownloadPath();
      final dir = Directory(downloadDir);
      int totalSize = 0;
      if (await dir.exists()) {
        await for (var entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
      return totalSize / (1024 * 1024 * 1024); // GB
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearCache() async {
    final cacheDir = await getTemporaryDirectory();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }

    final downloadDir = await getDownloadPath();
    final dir = Directory(downloadDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
  }
}
