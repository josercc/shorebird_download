import 'dart:async';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:path/path.dart';
import 'package:shorebird_downloader/src/commands/base_command.dart';
import 'package:dart_appwrite/dart_appwrite.dart' as appwrite;
import 'package:yaml/yaml.dart';

abstract class AppwriteBaseCommand extends BaseCommand {
  final defaultEndPoint = 'https://cloud.appwrite.io/v1';
  final databaseId = 'shorebird_patchs';
  final collectionId = 'patches';
  @override
  FutureOr? run() async {
    final root = argResults?['root'] ?? Platform.environment['PWD']!;

    final pubspecFile = File(join(root, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      stderr.writeln('路径$root下找不到 pubspec.yaml 文件');
      exitCode = 2;
    }
    final pubspecYaml =
        await pubspecFile.readAsString().then((value) => loadYaml(value));
    final appwriteConfig = pubspecYaml['appwrite'];
    final key = appwriteConfig['key'];
    final bucketId = appwriteConfig['bucketId'];
    final projectId = appwriteConfig['projectId'];
    final host = appwriteConfig['host'] ?? defaultEndPoint;
    if (key == null || bucketId == null && projectId == null && host == null) {
      stderr.writeln('缺少 appwrite 配置, 请按照配置进行配置!');
      exitCode = 2;
    }

    final client = appwrite.Client()
      ..setEndpoint(host)
      ..setProject(projectId)
      ..setKey(key);

    return appwriteRun(client, bucketId);
  }

  FutureOr? appwriteRun(Client client, String bucketId);
}
