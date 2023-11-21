import 'dart:async';
import 'dart:io';
import 'package:shorebird_downloader/shorebird_downloader.dart';

/// Shorebird 查询补丁下载器
class ShorebirdCheckDownloader {
  /// Shorebird 官方补丁下载器
  final ShorebirdCodePushManager codePush;

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

  final String appid;

  /// 是否已经进行开始检测
  bool isChecking = false;

  ShorebirdCheckDownloader({
    required this.appid,
    this.downloader,
    this.onDownloadProgress,
    this.onDownloadStart,
    this.onDownloadComplete,
    this.allowDownloadPatchHandle,
    ShorebirdCodePushManager? codePushManager,
  }) : codePush = codePushManager ?? ShorebirdCodePushManager();

  /// 当前是否正在下载补丁
  bool isDowningPatch = false;

  /// 检查补丁
  /// [needSleep] 是否需要等待 默认为 false
  /// [duration] 等待的时间 默认为一分钟
  Future<void> checkPatch({bool needSleep = false, Duration? duration}) async {
    if (isChecking) {
      return;
    }
    isChecking = true;
    final result = await _checkPatch();
    logger.d('👉检测补丁: $result');
    if (result.$2) {
      Timer.periodic(duration ?? const Duration(minutes: 1), (timer) async {
        final result = await _checkPatch();
        logger.d('👉检测补丁: $result');
        if (!result.$2) {
          timer.cancel();
        }
      });
    }
  }

  Future<(ShorebirdCodePushInfo, bool)> _checkPatch() async {
    final info = await codePush.check();
    logger.i('''
[${DateTime.now().toLocal()}]
Shorebird 热更新情况:【🛠】
isShorebirdAvailable: ${info.isShorebirdAvailable ? '🟢' : '🔴'}
isNewPatchAvailableForDownload: ${info.isNewPatchAvailableForDownload ? '🟢' : '🔴'}
currentPatchNumber: ${info.currentPatchNumber}
nextPatchNumber: ${info.nextPatchNumber}
isNewPatchReadyToInstall: ${info.isNewPatchReadyToInstall ? '🟢' : '🔴'}
''');

    if (!info.isShorebirdAvailable) {
      isChecking = false;
      return (info, false);
    } else if (info.isNewPatchReadyToInstall &&
        (Platform.isAndroid || Platform.isIOS)) {
      /// 补丁已经安装完毕 等待重启
      isDowningPatch = false;
      onDownloadComplete?.call();
      isChecking = false;
      return (info, false);
    } else if (!isDowningPatch && info.isNewPatchAvailableForDownload) {
      /// 当前没有在下载补丁 则开始下载补丁
      isDowningPatch = true;

      /// 是否允许下载
      final allowDownloadPatch = await allowDownloadPatchHandle?.call(
            info.currentPatchNumber ?? 0,
            info.nextPatchNumber ?? 0,
          ) ??
          true;

      if (!allowDownloadPatch) {
        return (info, false);
      } else {
        onDownloadStart?.call();
        downloadUpdateIfAvailable(info.nextPatchNumber ?? 0);
        return (info, true);
      }
    } else {
      return (info, true);
    }
  }

  /// 下载更新如果有插件激活 如果有自定义下载器 则使用自定义下载器 【不要自己调用】
  Future downloadUpdateIfAvailable(int nextPatchNumber) async {
    logger.d('downloadUpdateIfAvailable');
    if (downloader != null) {
      await downloader!.downloadPatch(progressCallback: onDownloadProgress);
    } else {
      /// 如果是官网就用过定时任务检测下载文件的大小
      /// 官方的暂时不支持
      // Timer.periodic(const Duration(seconds: 1), (timer) async {
      //   if (await codePush.isNewPatchReadyToInstall()) {
      //     timer.cancel();
      //   } else {
      //     final size = await readDownloadPatchSize(nextPatchNumber);
      //     onDownloadProgress?.call(size, null);
      //   }
      // });
      await codePush.downloadUpdateIfAvailable();
    }
    logger.i('✅下载补丁完毕');
  }

  /// 重启 App
  static restartApp() {
    exit(0);
  }

  /// 读取已经下载文件的大小
  Future<int> readDownloadPatchSize(int nextPatchNumber) async {
    final shorebirdDir = Directory(await shorebirdPath);
    if (await shorebirdDir.exists()) {
      logger.i('shorebirdDir: ${shorebirdDir.listSync(recursive: true)}');
    } else {
      logger.i('$shorebirdDir not exists');
    }

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
