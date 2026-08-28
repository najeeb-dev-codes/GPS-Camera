import 'dart:io';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

class PhotoShareService {
  PhotoShareService._();

  static Future<ShareResult> shareFile({
    required File file,
    required String fileName,
    required String mimeType,
    required String title,
    String? text,
    Rect? sharePositionOrigin,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: title,
        text: text,
        files: <XFile>[
          XFile(file.path, mimeType: mimeType),
        ],
        fileNameOverrides: <String>[fileName],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
