import 'package:shorebird_downloader/src/commands/base_command.dart';
import './init_command.dart';

class ShorebirdCommand extends BaseCommand {
  ShorebirdCommand() {
    addSubcommand(InitCommand());
  }

  @override
  String get description => '处理 Shorebird  相关';

  @override
  String get name => 'shorebird';
}
