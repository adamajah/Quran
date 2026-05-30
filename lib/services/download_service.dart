import 'dart:io';

import 'package:dio/dio.dart';

class DownloadService {
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};

  Future<void> downloadFile({
    required String url,
    required String savePath,
    required Function(int count, int total) onProgress,
    required Function() onCompleted,
    required Function(String error) onError,
    required String id,
  }) async {
    final partialPath = '$savePath.part';
    try {
      final cancelToken = CancelToken();
      _cancelTokens[id] = cancelToken;

      final response = await _dio.download(
        url,
        partialPath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Accept-Encoding': 'identity',
          }, // Ensure correct size reporting
        ),
      );

      await _validateAudioFile(response, partialPath);
      final completedFile = File(savePath);
      if (await completedFile.exists()) {
        await completedFile.delete();
      }
      await File(partialPath).rename(savePath);

      _cancelTokens.remove(id);
      onCompleted();
    } catch (e) {
      _cancelTokens.remove(id);
      final partialFile = File(partialPath);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      if (e is DioException) {
        if (CancelToken.isCancel(e)) {
          onError("PAUSED");
        } else if (e.type == DioExceptionType.connectionTimeout) {
          onError("Connection Timeout");
        } else if (e.type == DioExceptionType.badResponse) {
          onError("Server Error: ${e.response?.statusCode}");
        } else {
          onError("Network Error: ${e.message}");
        }
      } else {
        onError("Storage/System Error: ${e.toString()}");
      }
    }
  }

  void pauseDownload(String id) {
    _cancelTokens[id]?.cancel();
    _cancelTokens.remove(id);
  }

  Future<void> _validateAudioFile(
    Response<dynamic> response,
    String path,
  ) async {
    final contentType = response.headers.value(Headers.contentTypeHeader);
    if (contentType == null || !contentType.startsWith('audio/')) {
      throw FormatException('Server tidak mengirim file audio');
    }

    final file = File(path);
    if (!await file.exists() || await file.length() < 1024) {
      throw FormatException('File audio tidak lengkap');
    }

    final header = await file.openRead(0, 3).first;
    final hasId3Header =
        header.length >= 3 &&
        header[0] == 0x49 &&
        header[1] == 0x44 &&
        header[2] == 0x33;
    final hasMp3Frame =
        header.length >= 2 && header[0] == 0xFF && (header[1] & 0xE0) == 0xE0;
    if (!hasId3Header && !hasMp3Frame) {
      throw FormatException('Format audio tidak valid');
    }
  }
}
