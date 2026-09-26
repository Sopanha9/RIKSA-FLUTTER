import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

const localProfileMediaPrefix = 'local-profile-media:';

String localProfileMediaValue(String path) => '$localProfileMediaPrefix$path';

String? localProfileMediaPath(String? value) {
  final path = value?.trim();
  if (path == null || !path.startsWith(localProfileMediaPrefix)) return null;
  final result = path.substring(localProfileMediaPrefix.length);
  return result.isEmpty ? null : result;
}

Future<String> persistProfileImage({
  required XFile source,
  required String userId,
  required String kind,
}) async {
  final documents = await getApplicationDocumentsDirectory();
  final directory = Directory(
    '${documents.path}/riksa-profile-media/${_safeSegment(userId)}',
  );
  await directory.create(recursive: true);

  final extension = _supportedExtension(source.name);
  final version = DateTime.now().microsecondsSinceEpoch;
  final destination = File('${directory.path}/$kind-$version$extension');
  await File(source.path).copy(destination.path);
  return localProfileMediaValue(destination.path);
}

String _safeSegment(String value) =>
    value.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');

String _supportedExtension(String name) {
  final separator = name.lastIndexOf('.');
  if (separator < 0) return '.jpg';
  final extension = name.substring(separator).toLowerCase();
  return switch (extension) {
    '.jpg' || '.jpeg' || '.png' || '.webp' || '.heic' => extension,
    _ => '.jpg',
  };
}
