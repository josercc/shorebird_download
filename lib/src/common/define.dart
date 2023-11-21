import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

final logger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(
    methodCount: 0,
    printTime: true,
  ),
);

Future<String> get shorebirdPath async {
  if (Platform.isAndroid) {
    return getApplicationDocumentsDirectory().then(
      (value) => join(dirname(value.path), 'files', 'shorebird_updater'),
    );
  } else if (Platform.isIOS) {
    return getApplicationSupportDirectory().then(
      (e) => join(
        e.path,
        "shorebird",
        'shorebird_updater',
      ),
    );
  } else {
    throw UnsupportedError('暂时不支持此平台!');
  }
}

Future<String> downloadDirPath() {
  {
    if (Platform.isIOS) {
      return shorebirdPath.then((e) => join(e, "downloads"));
    } else if (Platform.isAndroid) {
      return getApplicationDocumentsDirectory().then(
        (value) => join(
          dirname(value.path),
          'code_cache',
          'shorebird_updater',
          'downloads',
        ),
      );
    } else {
      throw UnsupportedError('暂时不支持此平台!');
    }
  }
}

// downloads/$patchNumber for ios
// /data/user/0/com.winner.example/code_cache/shorebird_updater/downloads/$patchNumber
Future<String> downloadPath(int patchNumber) =>
    downloadDirPath().then((value) => join(value, patchNumber.toString()));

Future<String> patchDirPath() => shorebirdPath.then((e) => join(e, "patches"));

// patches/$patchNumber/dlc.vmcode
Future<String> patchCachePath(int patchNumber) =>
    patchDirPath().then((e) => join(e, patchNumber.toString(), "dlc.vmcode"));

// state.json
Future<String> get stateFilePath =>
    shorebirdPath.then((e) => join(e, "state.json"));

// patch_state.json
Future<String> get patchStateFilePath =>
    shorebirdPath.then((e) => join(e, "patches_state.json"));
