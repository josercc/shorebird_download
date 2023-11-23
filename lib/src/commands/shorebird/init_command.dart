import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:shorebird_downloader/src/commands/base_command.dart';
import 'package:shorebird_downloader/src/commands/shorebird/codes/v_0_8_1.dart';
import 'package:yaml/yaml.dart';

class InitCommand extends BaseCommand {
  @override
  String get description => '初始化 Shorebird  脚本插件';

  @override
  String get name => 'init';

  late Timer _timer;

  @override
  Future<int> runCommand() async {
    /// 检测  shorebird  是否安装
    final shorebirdCliPath =
        join(shorebirdDirPath, 'packages', 'shorebird_cli');
    if (!await Directory(shorebirdCliPath).exists()) {
      stderr.writeln('Shorebird 未安装');
      return 1;
    }

    /// 分析  lib/src/command_runner.dart 用于代码注入
    final runnerDartPath =
        join(shorebirdCliPath, 'lib', 'src', 'command_runner.dart');
    if (!await File(runnerDartPath).exists()) {
      stderr.writeln('$runnerDartPath 不存在');
      return 2;
    }

    final bytes = await File(runnerDartPath).readAsBytes();
    final originMd5 = md5.convert(bytes).toString();
    for (var version in suppertVersions) {
      final codeMd5 = md5.convert(utf8.encode(version.code)).toString();
      if (codeMd5 == originMd5) {
        stdout.writeln('已经安装完毕!');
        return 0;
      } else if (version.md5 == originMd5) {
        stdout.writeln('当前版本支持安装');
        break;
      }
    }
    return 0;
  }

  Future<SomeResolvedUnitResult> getResolvedUnit(
      AnalysisContextCollection contextCollection,
      String path,
      void Function(int index) progress) async {
    final completer = Completer<SomeResolvedUnitResult>();
    contextCollection
        .contextFor(path)
        .currentSession
        .getResolvedUnit(path)
        .then((value) => completer.complete(value));
    var index = 0;
    while (!completer.isCompleted) {
      await Future.delayed(const Duration(seconds: 1));
      index += 1;
      progress(index);
    }
    return completer.future;
  }
}

final shorebirdDirPath = join(Platform.environment['HOME']!, '.shorebird');

const suppertVersions = [
  v0_8_1,
];

class Md5Version {
  final String md5;
  final String code;

  const Md5Version(this.md5, this.code);
}
