import 'dart:async';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart' as appwrite;
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:darty_json_safe/darty_json_safe.dart';
import 'package:shorebird_downloader/src/commands/appwrite_base_command.dart';
import 'package:shorebird_downloader/src/patch_type.dart';

class AppwriteInitCommand extends AppwriteBaseCommand {
  @override
  String get description => '初始化 Appwrite';

  @override
  String get name => 'init';

  @override
  FutureOr? appwriteRun(appwrite.Client client, String bucketId) async {
    final databases = appwrite.Databases(client);

    try {
      await databases.get(databaseId: databaseId);
    } catch (_) {
      stdout.writeln('👉数据库[$databaseId]不存在，正在创建!');
      await databases.create(
        databaseId: databaseId,
        name: databaseId,
      );
    }

    try {
      await databases.getCollection(
          databaseId: databaseId, collectionId: collectionId);
    } catch (_) {
      stdout.writeln('👉表[$collectionId]不存在，正在创建!');
      await databases.createCollection(
        databaseId: databaseId,
        collectionId: collectionId,
        name: collectionId,
      );
    }

    final attributes = await databases.listAttributes(
      databaseId: databaseId,
      collectionId: collectionId,
    );

    final keys = attributes.attributes.map((e) => JSON(e)['key'].stringValue);
    if (!keys.contains('platform')) {
      stdout.writeln('👉字段[platform]不存在，正在创建!');
      await databases.createEnumAttribute(
        databaseId: databaseId,
        collectionId: collectionId,
        key: 'platform',
        elements: ['ios', 'android'],
        xrequired: true,
      );
    }
    if (!keys.contains('version')) {
      stdout.writeln('👉字段[version]不存在，正在创建!');
      await databases.createStringAttribute(
        databaseId: databaseId,
        collectionId: collectionId,
        key: 'version',
        xrequired: true,
        size: 20,
      );
    }
    if (!keys.contains('number')) {
      stdout.writeln('👉字段[number]不存在，正在创建!');
      await databases.createIntegerAttribute(
        databaseId: databaseId,
        collectionId: collectionId,
        key: 'number',
        xrequired: true,
      );
    }
    if (!keys.contains('patch_type')) {
      stdout.writeln('👉字段[patch_type]不存在，正在创建!');
      await databases.createEnumAttribute(
        databaseId: databaseId,
        collectionId: collectionId,
        key: 'patch_type',
        elements: PatchType.values.map((e) => e.name).toList(),
        xrequired: true,
      );
    }
    if (!keys.contains('fileId')) {
      stdout.writeln('👉字段[fileId]不存在，正在创建!');
      await databases.createStringAttribute(
        databaseId: databaseId,
        collectionId: collectionId,
        key: 'fileId',
        xrequired: true,
        size: 100,
      );
    }

    if (!keys.contains('shorebirdId')) {
      stdout.writeln('👉字段[shorebirdId]不存在，正在创建!');
      await databases.createStringAttribute(
        databaseId: databaseId,
        collectionId: collectionId,
        key: 'shorebirdId',
        xrequired: true,
        size: 200,
      );
    }

    final storage = Storage(client);
    try {
      await storage.getBucket(bucketId: bucketId);
    } catch (e) {
      stdout.writeln('👉存储桶[$bucketId]不存在，正在创建!');
      await storage.createBucket(
        bucketId: bucketId,
        name: bucketId,
      );
    }

    stdout.writeln('✅初始化成功!');
    exitCode = 0;
  }
}
