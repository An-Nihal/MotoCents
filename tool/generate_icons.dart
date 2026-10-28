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

  // Mipmap sizes
  final sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in sizes.entries) {
    final folder = 'android/app/src/main/res/${entry.key}';
    Directory(folder).createSync(recursive: true);
    final resized = img.copyResize(image, width: entry.value, height: entry.value, interpolation: img.Interpolation.linear);
    final outBytes = img.encodePng(resized);
    File('$folder/ic_launcher.png').writeAsBytesSync(outBytes);
    // Also save ic_launcher_round.png in case round icon is used
    File('$folder/ic_launcher_round.png').writeAsBytesSync(outBytes);
    print('Saved $folder (${entry.value}x${entry.value})');
  }

  print('All icons generated successfully!');
}
