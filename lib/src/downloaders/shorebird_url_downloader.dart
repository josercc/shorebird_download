import 'dart:io';

import 'package:darty_json_safe/darty_json_safe.dart';
import 'package:shorebird_downloader/src/downloaders/check_patch.dart';
import 'package:shorebird_downloader/src/downloaders/shorebird_downloader.dart';
import 'package:shorebird_downloader/src/downloaders/patch.dart';

class ShorebirdUrlDownloader extends ShorebirdDownloader {
  ShorebirdUrlDownloader({required super.appid});

  @override
  Future<Patch?> requestPatchInfo() async {
    late String platform;
    if (Platform.isIOS) {
      platform = 'ios';
    } else if (Platform.isAndroid) {
      platform = 'android';
    } else {
      throw UnsupportedError('暂时不支持此平台!');
    }
    final data = await CheckPatch(
      releaseVersion: await releaseVersion,
      appid: appid,
      currentPatchNumber: await currentPatchNumber(),
      platform: platform,
    ).checkPatch();
    final patch = JSON(data)['patch'];

    final number = patch['number'].int;
    final downloadUrl = patch['download_url'].string;
    if (number == null || downloadUrl == null) {
      return null;
    }
    return Patch(number: number, downloadUrl: downloadUrl);
  }
}
