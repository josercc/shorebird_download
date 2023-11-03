import 'package:dart_appwrite/models.dart';

class Patch {
  final int number;
  final String downloadUrl;

  const Patch({required this.number, required this.downloadUrl});
}

class AppwritePatch extends Patch {
  final String platform;
  final String version;
  final String patchType;
  final File file;

  AppwritePatch({
    required super.number,
    required super.downloadUrl,
    required this.platform,
    required this.version,
    required this.patchType,
    required this.file,
  });
}
