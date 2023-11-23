import 'dart:async';
import 'package:shorebird_downloader/src/commands/base_command.dart';

class AppwriteCommand extends BaseCommand {
  AppwriteCommand() {
    // addSubcommand(AppwriteUploadCommand());
    // addSubcommand(AppwriteInitCommand());
  }

  @override
  String get description => '可以将补丁上传到 Appwrite';

  @override
  String get name => 'appwrite';
}
