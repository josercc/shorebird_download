import 'package:dart_appwrite/models.dart';
import 'package:darty_json_safe/darty_json_safe.dart';

class Patch {
  final int number;
  final String downloadUrl;
  final String hash;

  const Patch(this.number, this.downloadUrl, this.hash);

  factory Patch.fromJson(Map json) => Patch(
        JSON(json)['number'].intValue,
        JSON(json)['download_url'].stringValue,
        JSON(json)['hash'].stringValue,
      );
}

class AppwritePatch extends Patch {
  final String platform;
  final String version;
  final String patchType;
  final File file;

  const AppwritePatch({
    required this.platform,
    required this.version,
    required this.patchType,
    required this.file,
    required int number,
    required String downloadUrl,
    required String hash,
  }) : super(number, downloadUrl, hash);
}

class PatchResponse {
  final bool patchAvailable;
  final Patch? patch;

  const PatchResponse(this.patchAvailable, [this.patch]);

  factory PatchResponse.fromJson(Map<String, dynamic> json) => PatchResponse(
        JSON(json)['patch_available'].boolValue,
        JSON(json)['patch'].unwrap<Map>().map((e) => Patch.fromJson(e)).value,
      );
}
