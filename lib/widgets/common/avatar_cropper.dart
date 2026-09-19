import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../design/tribe_design.dart';

class AvatarCropper {
  static Future<File?> crop(File sourceFile, BuildContext context) async {
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final t = TribeTheme(isDark);
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: sourceFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(
            toolbarColor: t.bg1,
            toolbarWidgetColor: t.milk,
            statusBarLight: true,
            backgroundColor: t.bg0,
            activeControlsWidgetColor: t.gold,
            cropFrameColor: t.gold,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
            showCropGrid: false,
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            doneButtonTitle: '✓',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      if (cropped == null) return null;
      return File(cropped.path);
    } catch (e) {
      // If cropping fails, return the original file
      return sourceFile;
    }
  }
}
