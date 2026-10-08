import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/widgets/image_sizing.dart';

void main() {
  int px({double? w, double? h}) => ImageSizing.targetPixelWidth(
    width: w,
    height: h,
    devicePixelRatio: 2.625,
    screenLogicalWidth: 411,
  );

  test('a 40dp avatar decodes at the 160px bucket', () {
    expect(px(w: 40, h: 40), 160);
  });

  test('infinite width means full screen width', () {
    expect(px(w: double.infinity, h: double.infinity), 1080);
    expect(px(w: double.infinity, h: 200), 1080);
  });

  test('unknown size falls back to the screen width', () {
    expect(px(), 1080);
  });

  test('the larger axis wins for cover boxes', () {
    expect(px(w: 100, h: 200), 720);
  });

  test('never exceeds the largest bucket', () {
    expect(
      ImageSizing.targetPixelWidth(
        width: 5000,
        devicePixelRatio: 3,
        screenLogicalWidth: 411,
      ),
      1280,
    );
  });
}
