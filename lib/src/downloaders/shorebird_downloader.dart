import 'dart:convert';
import 'dart:io';

import 'package:darty_json_safe/darty_json_safe.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shorebird_downloader/src/downloaders/patch.dart';

abstract class ShorebirdDownloader {
  final String appid;

  const ShorebirdDownloader({required this.appid});

  Future<String> get shorebirdPath async {
    if (Platform.isAndroid) {
      return getApplicationDocumentsDirectory().then(
        (value) => join(dirname(value.path), 'code_cache', 'shorebird_updater'),
      );
    } else if (Platform.isIOS) {
      return getApplicationSupportDirectory().then(
        (e) => join(
          e.path,
          "shorebird",
          'shorebird_updater',
        ),
      );
    } else {
      throw UnsupportedError('暂时不支持此平台!');
    }
  }

  // downloads/$patchNumber
  Future<String> downloadPath(int patchNumber) =>
      shorebirdPath.then((e) => join(e, "downloads", patchNumber.toString()));

  // patches/$patchNumber/dlc.vmcode
  Future<String> patchCachePath(int patchNumber) => shorebirdPath
      .then((e) => join(e, "patches", patchNumber.toString(), "dlc.vmcode"));

  // state.json
  Future<String> get stateFilePath =>
      shorebirdPath.then((e) => join(e, "state.json"));

  // patch_state.json
  Future<String> get patchStateFilePath =>
      shorebirdPath.then((e) => join(e, "patches_state.json"));
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

  Future downloadPatch([ProgressCallback? progressCallback]) async {
    final patch = await requestPatchInfo();
    if (patch == null) {
      return;
    }
    final downloadPatchFilePath = await downloadPath(patch.number);
    await Dio().downloadUri(
      Uri.parse(patch.downloadUrl),
      downloadPatchFilePath,
      onReceiveProgress: (count, total) {
        progressCallback?.call(count, total);
        debugPrint('shorebird download: $count/$total');
      },
    );
    final patchFile = File(downloadPatchFilePath);
    final patchCacheFile = File(await patchCachePath(patch.number));
    if (!await patchCacheFile.exists()) {
      await patchCacheFile.create(recursive: true);
    }
    debugPrint('copy ${patchFile.path} to ${patchCacheFile.path}');
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
    debugPrint('write patch state file');
    await patchStateFile.writeAsString(json.encode(patchState));
    debugPrint('✅下载补丁${patch.number}完成!');
  }

  Future<String> get releaseVersion async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }
}
