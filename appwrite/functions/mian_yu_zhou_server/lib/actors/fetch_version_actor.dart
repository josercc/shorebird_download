import 'package:appwrite_test/appwrite_test.dart';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:darty_json_safe/darty_json_safe.dart';
import 'package:version/version.dart';

/// 查询热更新新版本
class FetchVersionActor extends Actor {
  FetchVersionActor({required super.context});

  @override
  String get path => '/fetchVersion';

  @override
  Future<ActorResponse> runActor() async {
    final platform = JSON(context.req.bodyRaw)['platform'].string;
    final version = JSON(context.req.bodyRaw)['version'].string;
    if (platform == null) {
      return ActorResponse.failure(-1, 'platform 参数不存在!');
    }
    if (version == null) {
      return ActorResponse.failure(-1, 'version 参数不存在!');
    }

    final documentList = await databases.listDocuments(
      databaseId: 'shorebird_patchs',
      collectionId: 'versions',
      queries: [
        Query.equal('platform', platform),
      ],
    );

    final documents = documentList.documents.where((element) {
      return Version.parse(JSON(element.data)['version'].stringValue) >
          Version.parse(version);
    });

    if (documents.isEmpty) {
      return ActorResponse.success();
    } else {
      return ActorResponse.success(documents.last.toMap());
    }
  }
}
