import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shorebird_downloader/shorebird_downloader.dart';

class CheckPatch {
  final String releaseVersion;
  final String appid;
  final int currentPatchNumber;
  final String platform;
  // default is aarch64
  final String arch;

  CheckPatch({
    required this.releaseVersion,
    required this.appid,
    required this.currentPatchNumber,
    required this.platform,
    this.arch = 'aarch64',
  });
  Future<PatchResponse> checkPatch() async {
    //     curl -X "POST" "https://api.shorebird.dev/api/v1/patches/check" \
//      -H 'Content-Type: application/json; charset=utf-8' \
//      -d $'{
//   "platform": "ios", # 平台
//   "arch": "aarch64", # 架构
//   "release_version": "1.0.0+1697186586", # App 对应版本
//   "app_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", # App Id
//   "channel": "stable",
//   "patch_number": 0 # 当前补丁号
// }'
    const url = 'https://api.shorebird.dev/api/v1/patches/check';
    final dio = Dio(BaseOptions(
      responseType: ResponseType.json,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
      },
      method: 'POST',
    ));

    // {
    //   "patch_available": true,
    //   "patch": {
    //       "number": 1,
    //       "download_url": "xxxxxxxxx",
    //       "hash": "xxxxxxx"
    //   }
    // }
    final data = json.encode({
      'platform': platform,
      'arch': arch,
      'release_version': releaseVersion,
      'app_id': appid,
      'channel': 'stable',
      'patch_number': currentPatchNumber
    });

    logger.i('post data: $data');

    final response = await dio.request(
      url,
      onSendProgress: (count, total) {
        logger.i('shorebird send $count/$total [$url]');
      },
      onReceiveProgress: (count, total) {
        logger.i('shorebird receive $count/$total [$url]');
      },
      data: data,
    );
    // final response = Response(requestOptions: RequestOptions(), data: {
    //   "patch_available": true,
    //   "patch": {
    //     "number": 1,
    //     "download_url":
    //         "https://artifacts.shorebird.dev/9358ff5d-61cc-4338-a60d-6238b2cd182b/android/aarch64/17832/dlc.vmcode",
    //     "hash":
    //         "15aedb4049ba463f5a03db6094da3b166ebfc5e837739e225bc43265e14f8688"
    //   }
    // });
    logger.i('shorebird response: \n${json.encode(response.data)}');
    return PatchResponse.fromJson(response.data);
  }
}
