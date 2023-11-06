import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:shorebird_downloader/shorebird_downloader.dart';

/// Shorebird 查询补丁下载器
class ShorebirdCheckDownloader {
  /// Shorebird 官方补丁下载器
  final ShorebirdCodePush codePush = ShorebirdCodePush();

  /// 自定义  Shorebird  下载器 [因为官方锁死了其他下载 这个目前存在问题]
  final ShorebirdDownloader? downloader;

  /// 下载的回调 官方目前不支持
  final void Function(int count, int total)? onDownloadProgress;

  /// 自定义弹出更新  Dialog
  final void Function(int currentPatchNumber, int nextPatchNumber)?
      customShowUpdateDialog;

  ShorebirdCheckDownloader({
    this.downloader,
    this.onDownloadProgress,
    this.customShowUpdateDialog,
  });

  /// 当前是否正在下载补丁
  bool isDowningPatch = false;

  /// 检查补丁
  /// [needSleep] 是否需要等待 默认为 false
  /// [duration] 等待的时间 默认为一分钟
  Future<void> checkPatch([bool needSleep = false, Duration? duration]) async {
    if (needSleep) {
      final delayed = duration ?? const Duration(minutes: 1);
      logger.i('正在等待 ${delayed.inMilliseconds}毫秒, 等待下一次轮训!');
      await Future.delayed(duration ?? const Duration(minutes: 1));
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
      return;
    } else if (isNewPatchReadyToInstall &&
        (Platform.isAndroid || Platform.isIOS)) {
      isDowningPatch = false;
      if (customShowUpdateDialog != null) {
        customShowUpdateDialog!(currentPatchNumber, nextPatchNumber);
      }
    } else if (!isNewPatchAvailableForDownload) {
      await checkPatch(true, duration);
    } else if (!isDowningPatch) {
      isDowningPatch = true;
      await downloadUpdateIfAvailable(test);
      await checkPatch(true, duration);
    }
  }

  /// 下载更新如果有插件激活 如果有自定义下载器 则使用自定义下载器 【不要自己调用】
  Future downloadUpdateIfAvailable([bool test = false]) async {
    if (!test) return;
    if (downloader != null) {
      await downloader!.downloadPatch(onDownloadProgress);
    } else {
      await codePush.downloadUpdateIfAvailable();
    }
    logger.i('下载补丁完毕');
  }

  /// 展示更新弹框
  static showUpdateDialog(
      BuildContext context, int currentPatchNumber, int nextPatchNumber) {
    showDialog(
        context: context,
        builder: (context) => Dialog(
              child: Container(
                padding: const EdgeInsets.all(10.0),
                constraints:
                    const BoxConstraints(minHeight: 150, minWidth: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '有新的补丁$currentPatchNumber,需要更新!',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => restartApp(),
                        child: const Text('立即重启'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ));
  }

  /// 重启 App
  static restartApp() {
    exit(0);
  }
}
