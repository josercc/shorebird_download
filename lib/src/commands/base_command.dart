import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';

abstract class BaseCommand extends Command<int> {
  late String root;

  BaseCommand() {
    argParser.addOption('root', help: '自定义工程路径!');
  }

  @override
  FutureOr<int>? run() async {
    root = argResults?['root'] ?? Directory.current.path;
    exit(await runCommand());
  }

  Future<int> runCommand() => Future.value(0);
}
