import 'dart:async';
import 'package:appwrite_test/appwrite_test.dart';
import 'package:mian_yu_zhou_server/actors/fetch_version_actor.dart';

Future<dynamic> main(final context) {
  return RunMain(actors: [
    FetchVersionActor(context: context),
  ]).run(context);
}
