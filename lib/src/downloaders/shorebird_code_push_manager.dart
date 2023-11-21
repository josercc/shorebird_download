import 'package:shorebird_code_push/shorebird_code_push.dart';

class ShorebirdCodePushManager {
  final ShorebirdCodePush? codePush;
  final ShorebirdCodePushInfo codePushInfo;
  ShorebirdCodePushManager._({
    this.codePush,
    required this.codePushInfo,
  });

  factory ShorebirdCodePushManager() {
    return ShorebirdCodePushManager._(
      codePush: ShorebirdCodePush(),
      codePushInfo: ShorebirdCodePushInfo(),
    );
  }

  factory ShorebirdCodePushManager.test([ShorebirdCodePushInfo? codePushInfo]) {
    return ShorebirdCodePushManager._(
      codePushInfo: codePushInfo ?? ShorebirdCodePushInfo(),
    );
  }

  Future<int?> currentPatchNumber() async {
    if (codePush != null) {
      return codePush!.currentPatchNumber();
    } else {
      return codePushInfo.currentPatchNumber;
    }
  }

  Future<void> downloadUpdateIfAvailable() async {
    if (codePush != null) {
      await codePush!.downloadUpdateIfAvailable();
    } else {
      await Future.delayed(const Duration(minutes: 1));
    }
  }

  Future<bool> isNewPatchAvailableForDownload() async {
    if (codePush != null) {
      return codePush!.isNewPatchAvailableForDownload();
    } else {
      return codePushInfo.isNewPatchAvailableForDownload;
    }
  }

  Future<bool> isNewPatchReadyToInstall() async {
    if (codePush != null) {
      return codePush!.isNewPatchReadyToInstall();
    } else {
      return codePushInfo.isNewPatchReadyToInstall;
    }
  }

  bool isShorebirdAvailable() {
    if (codePush != null) {
      return codePush!.isShorebirdAvailable();
    } else {
      return codePushInfo.isShorebirdAvailable;
    }
  }

  Future<int?> nextPatchNumber() async {
    if (codePush != null) {
      return codePush!.nextPatchNumber();
    } else {
      return codePushInfo.nextPatchNumber;
    }
  }

  Future<ShorebirdCodePushInfo> check() async {
    if (codePush != null) {
      return ShorebirdCodePushInfo()
        ..currentPatchNumber = await currentPatchNumber()
        ..nextPatchNumber = await nextPatchNumber()
        ..isNewPatchAvailableForDownload =
            await isNewPatchAvailableForDownload()
        ..isNewPatchReadyToInstall = await isNewPatchReadyToInstall()
        ..isShorebirdAvailable = isShorebirdAvailable();
    } else {
      return codePushInfo;
    }
  }
}

class ShorebirdCodePushInfo {
  int? currentPatchNumber;
  int? nextPatchNumber;
  bool isNewPatchAvailableForDownload = false;
  bool isNewPatchReadyToInstall = false;
  bool isShorebirdAvailable = true;
}
