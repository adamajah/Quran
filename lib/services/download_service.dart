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
    try {
      final cancelToken = CancelToken();
      _cancelTokens[id] = cancelToken;

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Accept-Encoding': 'identity',
          }, // Ensure correct size reporting
        ),
      );

      _cancelTokens.remove(id);
      onCompleted();
    } catch (e) {
      _cancelTokens.remove(id);
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
}
