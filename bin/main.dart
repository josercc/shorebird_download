import 'package:args/command_runner.dart';
import 'package:shorebird_downloader/src/commands/appwrite/appwrite_command.dart';
import 'package:shorebird_downloader/src/commands/shorebird/shorebird_command.dart';

Future<void> main(List<String> args) async {
  final commandRunner = CommandRunner<int>(
    'shorebird_downloader',
    '对于 Shorebird 的补丁进行上传',
  );
  commandRunner.addCommand(AppwriteCommand());
  commandRunner.addCommand(ShorebirdCommand());
  await commandRunner.run(args);
}
