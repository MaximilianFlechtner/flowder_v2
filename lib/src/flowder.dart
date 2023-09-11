import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flowder_v2/src/core/downloader_core.dart';
import 'package:flowder_v2/src/utils/constants.dart';
import 'package:flowder_v2/src/utils/downloader_utils.dart';

export 'core/downloader_core.dart';
export 'progress/progress.dart';
export 'utils/utils.dart';

/// Global [typedef] that returns a `int` with the current byte on download
/// and another `int` with the total of bytes of the file.
typedef ProgressCallback = void Function(int count, int total);

/// Class used as a Static Handler
/// you can call the folowwing functions.
/// - Flowder.download: Returns an instance of [DownloaderCore]
/// - Flowder.initDownload -> this used at your own risk.
class Flowder {
  /// Start a new Download progress.
  /// Returns a [DownloaderCore]
  static Future<DownloaderCore> download(
      String url, DownloaderUtils options) async {
    try {
      // ignore: cancel_subscriptions
      final subscription = await initDownload(url, options);
      return DownloaderCore(subscription, options, url);
    } catch (e) {
      rethrow;
    }
  }

  /// Init a new Download, however this returns a [StreamSubscription]
  /// use at your own risk.
  static Future<StreamSubscription> initDownload(
      String url, DownloaderUtils options) async {
    var lastProgress = await options.progress.getProgress(url);
    final client = options.client ??
        Dio(BaseOptions(sendTimeout: const Duration(milliseconds: 60)));
    // ignore: cancel_subscriptions
    StreamSubscription? subscription;
    try {
      isDownloading = true;
      final file = await options.file.create(recursive: true);

      final response = await client.download(
        url,
        file,
        onReceiveProgress: (count, total) async {
          subscription!.pause();

          final currentProgress = count / total * 100;
          lastProgress = currentProgress.toInt();
          subscription.resume();

          options.progressCallback.call(count, total);
        },
      );

      return subscription!;
    } catch (e) {
      rethrow;
    }
  }
}
