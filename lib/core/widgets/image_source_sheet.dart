import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/gen/app_localizations.dart';

/// Asks whether a photo should come from the gallery or the camera.
///
/// Returns null when the sheet is dismissed.
Future<ImageSource?> showImageSourceSheet(BuildContext context) =>
    showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const ValueKey('pick-from-gallery'),
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.photoFromGallery),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                key: const ValueKey('pick-from-camera'),
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.photoFromCamera),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
