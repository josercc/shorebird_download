import 'dart:io';

import 'package:appwrite_test/appwrite_test.dart';
import 'package:mian_yu_zhou_server/main.dart'
    as appwrite_functions_mian_yu_zhou_server;

void main(List<String> args) async {
  final context = TestContext(
    {
      "APPWRITE_API_KEY":
          "df02fe9c801ef2d89e92fd522dd6d62adbb7e0ecacf4a039fdf915825828579d29729141511fc6728927dea9c3512cf2884925bb847be87a6b3eb80506042027cf76ebc44fd32605428acbe6ba8a82efd867310ddf63935de75dc8b2a0f1c7567b29a1fcf9eccf1f0cafd96ac1a2018c60742af237b876adc5dcf358ef7626b2",
      "APPWRITE_FUNCTION_RUNTIME_NAME": "Dart",
      "HOSTNAME": "655eff8d02d8b",
      "HOME": "/root",
      "OLDPWD": "/usr/local/server",
      "PATH":
          "/usr/lib/dart/bin:/root/.pub-cache/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
      "APPWRITE_FUNCTION_NAME": "mian_yu_zhou_server",
      "OPEN_RUNTIMES_ENTRYPOINT": "lib/main.dart",
      "INERNAL_EXECUTOR_HOSTNAME": "exc3",
      "APPWRITE_FUNCTION_RUNTIME_VERSION": "3.1",
      "APPWRITE_FUNCTION_ID": "mian_yu_zhou_server",
      "DART_SDK": "/usr/lib/dart",
      "PWD": "/usr/local/server",
      "OPEN_RUNTIMES_HOSTNAME": "exc3",
      "APPWRITE_FUNCTION_DEPLOYMENT": "655efdb32560e35046af",
      "OPEN_RUNTIMES_SECRET": "3577cb23b33f3f90fa4a673951c9fd3a",
      "APPWRITE_FUNCTION_PROJECT_ID": "mianyuzhouapp"
    },
    req: TestReq(
      path: '/fetchVersion',
      method: 'GET',
      bodyRaw: {
        'platform': 'android',
        'version': '0.7.0+1',
      },
    ),
  );

  await appwrite_functions_mian_yu_zhou_server.main(context);
  exit(0);
}
