import 'package:args/command_runner.dart';

abstract class BaseCommand extends Command {
  BaseCommand() {
    argParser.addOption('root', help: '自定义工程路径!');
  }
}
