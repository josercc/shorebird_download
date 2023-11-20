import 'dart:convert';
import 'dart:io';

import 'package:darty_json_safe/darty_json_safe.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:shorebird_downloader/src/common/define.dart';
import 'package:shorebird_downloader/src/downloaders/patch.dart';

abstract class ShorebirdDownloader {
  final String appid;

  const ShorebirdDownloader({required this.appid});

  Future<int> currentPatchNumber() async {
    final file = File(await patchStateFilePath);
    if (!await file.exists()) return 0;
    // patches_state.json
// {
//   "last_booted_patch": {
//     "number": 1, // 上一次补丁的版本号
//     "size": 18434176 // 上一次补丁的大小
//   },
//   "next_boot_patch": {
//     "number": 1, // 下一次补丁的版本号
//     "size": 18434176 // 下一次补丁的大小
//   },
//   "highest_seen_patch_number": 1
// }
    final jsonText = await file.readAsString();
    final jsonValue = json.decode(jsonText);
    return JSON(jsonValue)['last_booted_patch']['number'].int ?? 0;
  }

  Future<Patch?> requestPatchInfo();

  Future downloadPatchIncache(
    Patch patch,
    String downloadPatchFilePath, {
    ProgressCallback? progressCallback,
    String? downloadUrl,
  }) async {
    await Dio().downloadUri(
      Uri.parse(downloadUrl ?? patch.downloadUrl),
      downloadPatchFilePath,
      onReceiveProgress: (count, total) {
        progressCallback?.call(count, total);
        logger.i('shorebird download: $count/$total');
      },
    );
  }

  Future downloadPatch(
      {ProgressCallback? progressCallback, String? downloadUrl}) async {
    logger.i('[$runtimeType] start requestPatchInfo');
    final patch = await requestPatchInfo();
    if (patch == null) {
      return;
    }
    final downloadPatchFilePath = await downloadPath(patch.number);
    logger.i('[$runtimeType] start download patch');
    await downloadPatchIncache(
      patch,
      downloadPatchFilePath,
      progressCallback: progressCallback,
      downloadUrl: downloadUrl,
    );
    final patchFile = File(downloadPatchFilePath);
    final patchCacheFile = File(await patchCachePath(patch.number));
    if (!await patchCacheFile.exists()) {
      await patchCacheFile.create(recursive: true);
    }
    logger.i('copy ${patchFile.path} to ${patchCacheFile.path}');
    await patchFile.copy(patchCacheFile.path);
    final lastPatchNumber = await currentPatchNumber();
    final lastPatchFile =
        File(join(await shorebirdPath, 'patches', '$lastPatchNumber'));
    final lastPatchSize =
        await lastPatchFile.exists() ? await lastPatchFile.length() : 0;
    final size = await patchFile.length();
    Map? lastPatch;
    if (lastPatchNumber != 0) {
      lastPatch = {
        "number": lastPatchNumber, // 上一次补丁的版本号
        "size": lastPatchSize // 上一次补丁的大小
      };
    }
    final patchState = {
      "last_booted_patch": lastPatch,
      "next_boot_patch": {
        "number": patch.number, // 下一次补丁的版本号
        "size": size // 下一次补丁的大小
      },
      "highest_seen_patch_number": patch.number
    };
    final patchStateFile = File(await patchStateFilePath);
    await patchStateFile.create(recursive: true);
    logger.i('write patch state file');
    await patchStateFile.writeAsString(json.encode(patchState));
    logger.i('✅下载补丁${patch.number}完成!');
  }

  Future<String> get releaseVersion async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  String get platform {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      throw UnsupportedError('暂时不支持此平台!');
    }
  }
}
