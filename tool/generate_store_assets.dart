// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/app_logo.png');
  final image = img.decodeImage(file.readAsBytesSync())!;

  // 512x512 for Amazon Appstore & APKPure
  final img512 = img.copyResize(image, width: 512, height: 512, interpolation: img.Interpolation.linear);
  File('store_assets/icon_512x512.png').writeAsBytesSync(img.encodePng(img512));

  // 1024x1024
  File('store_assets/icon_1024x1024.png').writeAsBytesSync(img.encodePng(image));

  print('Store icons generated successfully in store_assets/');
}

