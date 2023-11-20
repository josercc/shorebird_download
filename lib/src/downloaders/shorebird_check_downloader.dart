import 'dart:async';
import 'dart:io';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:shorebird_downloader/shorebird_downloader.dart';

/// Shorebird 查询补丁下载器
class ShorebirdCheckDownloader {
  /// Shorebird 官方补丁下载器
  final ShorebirdCodePush codePush = ShorebirdCodePush();

  /// 自定义  Shorebird  下载器 [因为官方锁死了其他下载 这个目前存在问题]
  final ShorebirdDownloader? downloader;

  /// 下载的回调 官方目前不支持
  /// [count] 当前下载的大小
  /// [total] 总大小
  final void Function(int count, int? total)? onDownloadProgress;

  /// 开始下载的回调
  final void Function()? onDownloadStart;

  /// 下载完成的回调
  final void Function()? onDownloadComplete;

  /// 是否允许下载补丁
  /// [currentPatchNumber] 当前补丁
  /// [nextPatchNumber] 下一个补丁
  final Future<bool> Function(int currentPatchNumber, int nextPatchNumber)?
      allowDownloadPatchHandle;

  ShorebirdCheckDownloader({
    this.downloader,
    this.onDownloadProgress,
    this.onDownloadStart,
    this.onDownloadComplete,
    this.allowDownloadPatchHandle,
  });

  /// 当前是否正在下载补丁
  bool isDowningPatch = false;

  /// 检查补丁
  /// [needSleep] 是否需要等待 默认为 false
  /// [duration] 等待的时间 默认为一分钟
  Future<void> checkPatch({bool needSleep = false, Duration? duration}) async {
    if (needSleep) {
      final delayed = duration ?? const Duration(minutes: 1);
      logger.i('正在等待 ${delayed.inMilliseconds}毫秒, 等待下一次轮训!');
      await Future.delayed(delayed);
    }
    final isShorebirdAvailable = codePush.isShorebirdAvailable();
    final isNewPatchAvailableForDownload =
        await codePush.isNewPatchAvailableForDownload();
    final currentPatchNumber = await codePush.currentPatchNumber() ?? 0;
    final nextPatchNumber = await codePush.nextPatchNumber() ?? 0;
    final isNewPatchReadyToInstall = await codePush.isNewPatchReadyToInstall();

    logger.i('''
[${DateTime.now().toLocal()}]
Shorebird 热更新情况:
isShorebirdAvailable: $isShorebirdAvailable
isNewPatchAvailableForDownload: $isNewPatchAvailableForDownload
currentPatchNumber: $currentPatchNumber
nextPatchNumber: $nextPatchNumber
isNewPatchReadyToInstall: $isNewPatchReadyToInstall
''');

    await didCheckPatchSuccess(
      isShorebirdAvailable: isShorebirdAvailable,
      isNewPatchAvailableForDownload: isNewPatchAvailableForDownload,
      isNewPatchReadyToInstall: isNewPatchReadyToInstall,
      currentPatchNumber: currentPatchNumber,
      nextPatchNumber: nextPatchNumber,
      test: true,
      duration: duration,
    );
  }

  /// 已经检测补丁完毕回调 【这个不要自己调用】
  didCheckPatchSuccess({
    required bool isShorebirdAvailable,
    required bool isNewPatchAvailableForDownload,
    required bool isNewPatchReadyToInstall,
    required int currentPatchNumber,
    required int nextPatchNumber,
    bool test = false,
    Duration? duration,
  }) async {
    if (!isShorebirdAvailable) {
      /// Shorebird 服务没有激活
      return;
    } else if (isNewPatchReadyToInstall &&
        (Platform.isAndroid || Platform.isIOS)) {
      /// 补丁已经安装完毕 等待重启
      isDowningPatch = false;
      onDownloadComplete?.call();
    } else if (!isNewPatchAvailableForDownload) {
      /// 没有新的补丁激活
      await checkPatch(needSleep: true, duration: duration);
    } else if (!isDowningPatch) {
      /// 当前没有在下载补丁 则开始下载补丁
      isDowningPatch = true;

      /// 是否允许下载
      final allowDownloadPatch = await allowDownloadPatchHandle?.call(
            currentPatchNumber,
            nextPatchNumber,
          ) ??
          true;

      if (!allowDownloadPatch) return;
      onDownloadStart?.call();
      await downloadUpdateIfAvailable(nextPatchNumber, test);
      await checkPatch(needSleep: true, duration: duration);
    }
  }

  /// 下载更新如果有插件激活 如果有自定义下载器 则使用自定义下载器 【不要自己调用】
  Future downloadUpdateIfAvailable(int nextPatchNumber,
      [bool test = false]) async {
    if (!test) return;
    if (downloader != null) {
      await downloader!.downloadPatch(progressCallback: onDownloadProgress);
    } else {
      /// 如果是官网就用过定时任务检测下载文件的大小
      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (await codePush.isNewPatchReadyToInstall()) {
          timer.cancel();
        } else {
          final size = await readDownloadPatchSize(nextPatchNumber);
          onDownloadProgress?.call(size, null);
        }
      });
      await codePush.downloadUpdateIfAvailable();
    }
    logger.i('下载补丁完毕');
  }

  /// 重启 App
  static restartApp() {
    exit(0);
  }

  /// 读取已经下载文件的大小
  Future<int> readDownloadPatchSize(int nextPatchNumber) async {
    final downloadPatchFile = File(await downloadPath(nextPatchNumber));
    if (await downloadPatchFile.exists()) {
      return downloadPatchFile.length();
    } else {
      final patchFile = File(await patchCachePath(nextPatchNumber));
      if (await patchFile.exists()) {
        return patchFile.length();
      } else {
        return 0;
      }
    }
  }
}
