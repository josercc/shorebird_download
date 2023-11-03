import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:darty_json_safe/darty_json_safe.dart';
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
    return requestNewPatch();
  }

  @override
  Future downloadPatchIncache(
    Patch patch,
    String downloadPatchFilePath, [
    ProgressCallback? progressCallback,
  ]) async {
    progressCallback?.call(0, 1);
    final data = await storage.getFileDownload(
      bucketId: bucketId,
      fileId: patch.downloadUrl,
    );
    progressCallback?.call(1, 1);
    final file = File(downloadPatchFilePath);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsBytes(data);
  }

  Future<AppwritePatch?> requestNewPatch() async {
    final databases = Databases(client);
    final version = await releaseVersion;
    final documents = await databases.listDocuments(
      databaseId: 'shorebird_patchs',
      collectionId: 'patches',
      queries: [
        Query.equal('shorebirdId', appid),
        Query.equal('platform', platform),
        Query.equal('version', version),
        Query.orderDesc('number'),
      ],
    );
    if (documents.documents.isEmpty) {
      return null;
    }
    final document = documents.documents.first;
    final dataJson = JSON(document.data);
    final patchNumber = dataJson['number'].intValue;
    if (patchNumber <= await currentPatchNumber()) {
      return null;
    }
    final fileId = dataJson['fileId'].stringValue;
    final file = await storage.getFile(bucketId: bucketId, fileId: fileId);
    return AppwritePatch(
      number: patchNumber,
      downloadUrl: fileId,
      platform: platform,
      version: version,
      patchType: dataJson['patch_type'].stringValue,
      file: file,
    );
  }
}
