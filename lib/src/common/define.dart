import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

final logger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(methodCount: 0),
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

// downloads/$patchNumber for ios
// /data/user/0/com.winner.example/code_cache/shorebird_updater/downloads
Future<String> downloadPath(int patchNumber) {
  if (Platform.isIOS) {
    return shorebirdPath
        .then((e) => join(e, "downloads", patchNumber.toString()));
  } else if (Platform.isAndroid) {
    return getApplicationDocumentsDirectory().then(
      (value) => join(
        dirname(value.path),
        'code_cache',
        'shorebird_updater',
        'downloads',
        patchNumber.toString(),
      ),
    );
  } else {
    throw UnsupportedError('暂时不支持此平台!');
  }
}

// patches/$patchNumber/dlc.vmcode
Future<String> patchCachePath(int patchNumber) => shorebirdPath
    .then((e) => join(e, "patches", patchNumber.toString(), "dlc.vmcode"));

// state.json
Future<String> get stateFilePath =>
    shorebirdPath.then((e) => join(e, "state.json"));

// patch_state.json
Future<String> get patchStateFilePath =>
    shorebirdPath.then((e) => join(e, "patches_state.json"));
