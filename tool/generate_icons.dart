// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const srcPath = 'C:/Users/drclo/.gemini/antigravity/brain/605ac026-2488-42a4-8d11-5e61ea3cce5b/.user_uploaded/media_1793186432055_3779661e.jpg';
  final bytes = File(srcPath).readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Failed to decode image');
    exit(1);
  }

  print('Decoded source image: ${image.width}x${image.height}');

  // Save to assets/images/app_logo.png
  final pngBytes = img.encodePng(image);
  File('assets/images/app_logo.png').writeAsBytesSync(pngBytes);
  print('Saved assets/images/app_logo.png');

  // Android Mipmap sizes
  final androidSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in androidSizes.entries) {
    final folder = 'android/app/src/main/res/${entry.key}';
    Directory(folder).createSync(recursive: true);
    final resized = img.copyResize(image, width: entry.value, height: entry.value, interpolation: img.Interpolation.linear);
    final outBytes = img.encodePng(resized);
    File('$folder/ic_launcher.png').writeAsBytesSync(outBytes);
    File('$folder/ic_launcher_round.png').writeAsBytesSync(outBytes);
    print('Saved Android $folder (${entry.value}x${entry.value})');
  }

  // iOS AppIcon sizes
  final iosIcons = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  const iosFolder = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  Directory(iosFolder).createSync(recursive: true);

  for (final entry in iosIcons.entries) {
    final resized = img.copyResize(image, width: entry.value, height: entry.value, interpolation: img.Interpolation.linear);
    final outBytes = img.encodePng(resized);
    File('$iosFolder/${entry.key}').writeAsBytesSync(outBytes);
    print('Saved iOS $iosFolder/${entry.key} (${entry.value}x${entry.value})');
  }

  print('All Android and iOS icons generated successfully!');
}
