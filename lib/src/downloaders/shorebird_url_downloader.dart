import 'dart:convert';
import 'dart:io';

import 'package:darty_json_safe/darty_json_safe.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shorebird_downloader/src/downloaders/shorebird_downloader.dart';
import 'package:shorebird_downloader/src/downloaders/patch.dart';

class ShorebirdUrlDownloader extends ShorebirdDownloader {
  ShorebirdUrlDownloader({required super.appid});

  @override
  Future<Patch?> requestPatchInfo() async {
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
    late String platform;
    if (Platform.isIOS) {
      platform = 'ios';
    } else if (Platform.isAndroid) {
      platform = 'android';
    } else {
      throw UnsupportedError('暂时不支持此平台!');
    }
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
      'release_version': await releaseVersion,
      'app_id': appid,
      'channel': 'stable',
      'patch_number': await currentPatchNumber()
    });

    debugPrint('post data: $data');

    final response = await dio.request(
      url,
      onSendProgress: (count, total) {
        debugPrint('shorebird send $count/$total [$url]');
      },
      onReceiveProgress: (count, total) {
        debugPrint('shorebird receive $count/$total [$url]');
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
    debugPrint('shorebird response: \n${json.encode(response.data)}');
    final patch = JSON(response.data)['patch'];

    final number = patch['number'].int;
    final downloadUrl = patch['download_url'].string;
    if (number == null || downloadUrl == null) {
      return null;
    }
    return Patch(number: number, downloadUrl: downloadUrl);
  }
}
