# shorebird_downloader

This is a plug-in that supports `Shorebird` to customize the patch download address and to keep an eye on the download progress.

Of course, in addition to the download function, you still need to get the other patch status related to Shorebird through the `shorebird_code_push` plugin.

## How To install

```shell
flutter pub add shorebird_downloader
```

## How to use

```dart
final downloader =
    ShorebirdUrlDownloader(appid: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx');
await downloader.downloadPatch((size,totol) => print("$size/$totol"));
```

## How to custom download url

If you feel that shorebird's CDN access is still slow or inaccessible, you can upload the patch to your own server in advance.


You can customize the following code to implement it.

```dart
class ShorebirdCustomUrlDownloader extends ShorebirdDownloader {
  ShorebirdUrlDownloader({required super.appid});

  @override
  Future<Patch?> requestPatchInfo() async {

    // TODO: http request custom your server url
    // [number] represents the latest patch number
    // [downloadUrl] represents the latest patch number
    return Patch(number: number, downloadUrl: downloadUrl);
  }
}
```

Then you can use it as usual.

```dart
final downloader =
    ShorebirdCustomUrlDownloader(appid: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx');
await downloader.downloadPatch((size,totol) => print("$size/$totol"));
```

## uploader

We now support uploading to the Appwrite server

### install uploader

```
dart pub global activate shorebird_downloader
```

### uploader to appwrite server

The first step is to configure your factory files

```yaml
# pubspec.yaml
appwrite:
  key: xxxxxx
  projectId: xxxxx
  bucketId: xxxx
```

```yaml
# shorebird.yaml
app_id: xxxxx
```

You can use the following command to upload the latest patch to Appwrite.

```shell
# in current shorebird project
shorebird_patch_uploader appwrite --platform [ios/android] 
```

To download updates directly from appwrite, you need to use the following code

```dart
final downloader =
    ShorebirdAppwriteDownloader(
      appid: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
      projectId: 'xxxxx',
      bucketId: 'bucketId',
      key: 'key',
      // endPoint: 'custom appwrite endpoint normal is https://cloud.appwrite.io/v1'
    );
await downloader.downloadPatch((size,totol) => print("$size/$totol"));
```