import 'package:flutter/material.dart';
import 'package:storage_space/storage_space.dart';
import '../services/storage_service.dart';

class StorageProvider with ChangeNotifier {
  final StorageService _storageService;
  StorageSpace? _storageSpace;
  double _appUsageSize = 0.0;
  bool _isLoading = false;

  StorageProvider(this._storageService) {
    refreshStorageInfo();
  }

  StorageSpace? get storageSpace => _storageSpace;
  double get appUsageSize => _appUsageSize;
  bool get isLoading => _isLoading;

  Future<void> refreshStorageInfo() async {
    _isLoading = true;
    notifyListeners();

    _storageSpace = await _storageService.getStorageInfo();
    _appUsageSize = await _storageService.getAppUsageSize();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _storageService.clearCache();
    await refreshStorageInfo();
  }
}
