import 'dart:developer';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dio/dio.dart';
import 'package:shorebird_downloader/shorebird_downloader.dart';
import 'package:shorebird_downloader/src/downloaders/patch.dart';

class ShorebirdAppwriteDownloader extends ShorebirdDownloader {
  final String endPoint;
  final String projectId;
  final String bucketId;
  final String key;
  final Client client = Client();
  late Storage storage;
  ShorebirdAppwriteDownloader({
    required super.appid,
    required this.projectId,
    required this.bucketId,
    required this.key,
    this.endPoint = 'https://cloud.appwrite.io/v1',
  }) {
    client
      ..setEndpoint(endPoint)
      ..setProject(projectId)
      ..setKey(key);
    storage = Storage(client);
  }

  @override
  Future<Patch?> requestPatchInfo() async {
    late String platform;
    if (Platform.isAndroid) {
      platform = 'android';
    } else if (Platform.isIOS) {
      platform = 'ios';
    } else {
      throw UnsupportedError('暂时不支持此平台!');
    }

    final version = await releaseVersion;
    final files = await storage
        .listFiles(bucketId: bucketId)
        .then((value) => value.files)
        .then((value) =>
            value.where((element) => element.name.split('_').length == 4));
    final numbers = files
        .map((e) => e.name)
        .map((e) => e.split('_'))
        .where((element) {
          return element[0] == platform && element[1] == version;
        })
        .map((e) => int.parse(e[2]))
        .toList();

    numbers.sort();
    final currentNumber = await currentPatchNumber();
    final lastNumber = numbers.last;
    if (numbers.last <= currentNumber) {
      log('平台:$platform 版本:$version 已是最新补丁');
      return null;
    }

    final file = files.firstWhere(
        (element) => int.parse(element.name.split('_')[2]) == lastNumber);
    return Patch(number: lastNumber, downloadUrl: file.$id);
  }

  @override
  Future downloadPatchIncache(
    Patch patch,
    String downloadPatchFilePath, [
    ProgressCallback? progressCallback,
  ]) async {
    final data = await storage.getFileDownload(
      bucketId: bucketId,
      fileId: patch.downloadUrl,
    );
    final file = File(downloadPatchFilePath);
    if (!await file.exists()) {
      await file.create();
    }
    await File(downloadPatchFilePath).writeAsBytes(data);
  }
}
