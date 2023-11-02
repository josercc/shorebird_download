import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

class CheckPatch {
  final String releaseVersion;
  final String appid;
  final int currentPatchNumber;
  final String platform;

  CheckPatch({
    required this.releaseVersion,
    required this.appid,
    required this.currentPatchNumber,
    required this.platform,
  });
  Future<dynamic> checkPatch() async {
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
      'arch': 'aarch64',
      'release_version': releaseVersion,
      'app_id': appid,
      'channel': 'stable',
      'patch_number': currentPatchNumber
    });

    log('post data: $data');

    final response = await dio.request(
      url,
      onSendProgress: (count, total) {
        log('shorebird send $count/$total [$url]');
      },
      onReceiveProgress: (count, total) {
        log('shorebird receive $count/$total [$url]');
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
    log('shorebird response: \n${json.encode(response.data)}');
    return response.data;
  }
}
