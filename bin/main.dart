import 'package:args/command_runner.dart';
import 'package:shorebird_downloader/src/commands/appwrite/appwrite_command.dart';

Future<void> main(List<String> args) async {
  final commandRunner = CommandRunner(
    'shorebird_patch_uploader',
    '对于 Shorebird 的补丁进行上传',
  );
  commandRunner.addCommand(AppwriteCommand());
  await commandRunner.run(args);
}
