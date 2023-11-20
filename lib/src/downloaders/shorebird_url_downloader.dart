import 'dart:io';
import 'package:shorebird_downloader/src/downloaders/check_patch.dart';
import 'package:shorebird_downloader/src/downloaders/shorebird_downloader.dart';
import 'package:shorebird_downloader/src/downloaders/patch.dart';

class ShorebirdUrlDownloader extends ShorebirdDownloader {
  ShorebirdUrlDownloader({required super.appid});

  @override
  Future<Patch?> requestPatchInfo() async {
    late String platform;
    late String arch;
    if (Platform.isIOS) {
      platform = 'ios';
      arch = 'aarch64';
    } else if (Platform.isAndroid) {
      platform = 'android';
      arch = 'aarch64';
    } else {
      throw UnsupportedError('暂时不支持此平台!');
    }
    final data = await CheckPatch(
      releaseVersion: await releaseVersion,
      appid: appid,
      currentPatchNumber: await currentPatchNumber(),
      platform: platform,
      arch: arch,
    ).checkPatch();
    return data.patch;
  }
}
