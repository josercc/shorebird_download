import 'dart:async';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:darty_json_safe/darty_json_safe.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:shorebird_downloader/src/commands/appwrite/appwrite_base_command.dart';
import 'package:shorebird_downloader/src/downloaders/check_patch.dart';
import 'package:shorebird_downloader/src/patch_type.dart';
import 'package:yaml/yaml.dart';

class AppwriteUploadCommand extends AppwriteBaseCommand {
  @override
  String get description => '上传补丁到 Appwrite  服务器';

  @override
  String get name => 'upload';

  AppwriteUploadCommand() {
    argParser.addOption('platform', help: '平台 ios/android', mandatory: true);
    argParser.addOption(
      'patchType',
      help:
          '请输入补丁类型 [${PatchType.values.map((e) => e.name).join(', ')}] 默认为${PatchType.cannotSkip.name}',
    );
  }

  @override
  Future<int> appwriteRun(Client client, String bucketId) async {
    final patchType = argResults?['patchType'] ?? PatchType.cannotSkip.name;
    final root = argResults?['root'] ?? Platform.environment['PWD']!;
    final platform = argResults?['platform']!;
    final shorebirdFile = File(join(root, 'shorebird.yaml'));
    if (!await shorebirdFile.exists()) {
      stderr.writeln('路径$root下找不到 shorebird.yaml 文件');
      return 2;
    }
    final pubspecFile = File(join(root, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      stderr.writeln('路径$root下找不到 pubspec.yaml 文件');
      return 2;
    }
    String appid = await shorebirdFile
        .readAsString()
        .then((value) => loadYaml(value)['app_id']);

    final pubspecYaml =
        await pubspecFile.readAsString().then((value) => loadYaml(value));
    String version = pubspecYaml['version'];
    final data = await CheckPatch(
      releaseVersion: version,
      appid: appid,
      currentPatchNumber: 0,
      platform: platform,
      arch: platform == 'ios' ? 'aarch64' : 'arm',
    ).checkPatch();
    final patch = JSON(data)['patch'];
    final number = patch['number'].intValue;
    final downloadUrl = patch['download_url'].stringValue;
    final fileName = '${appid}_${platform}_${version}_${number}_.vmcode';
    final downloadCachePath = join(
      Platform.environment['HOME']!,
      'shorebird_download_cache',
      fileName,
    );
    final Storage storage = Storage(client);

    final list = await storage
        .listFiles(bucketId: bucketId)
        .then((value) => value.files)
        .then((value) => value.map((e) => e.name).toList());

    if (list.contains(fileName)) {
      stderr.writeln('🔴补丁文件已存在!');
      return 1;
    }
    await Dio().downloadUri(
      Uri.parse(downloadUrl),
      downloadCachePath,
      onReceiveProgress: (count, total) {
        stdout.writeln('👎下载补丁到本地缓存进度 $count / $total');
      },
    );

    final fileId = ID.unique();
    final file = await storage.createFile(
      bucketId: bucketId,
      fileId: fileId,
      file: InputFile.fromPath(path: downloadCachePath, filename: fileName),
      onProgress: (p0) {
        stdout
            .writeln('👍上传补丁到 Appwrite 进度 ${p0.progress.toStringAsFixed(2)}%');
      },
    );
    final databases = Databases(client);
    await databases.createDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: ID.unique(),
      data: {
        'platform': platform,
        'version': version,
        'number': number,
        'patch_type': patchType,
        'fileId': file.$id,
        'shorebirdId': appid,
      },
    );
    stdout.writeln('✅上传成功! 文件id:${file.$id}  文件名:$fileName');
    return 0;
  }
}
