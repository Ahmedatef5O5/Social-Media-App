import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/core/cache/utils/cloudinary_url_extensions.dart';

void main() {
  const base = 'https://res.cloudinary.com/demo/image/upload';

  test('replaces the upload-time chain', () {
    expect(
      '$base/c_limit,w_1280,h_1280,q_auto,f_auto/v1/posts/a.jpg'
          .cloudinarySizedImageUrl(512),
      '$base/c_limit,w_512,q_auto,f_auto/v1/posts/a.jpg',
    );
  });

  test('inserts a chain into a raw migrated URL', () {
    expect(
      '$base/v1/posts/a.jpg'.cloudinarySizedImageUrl(512),
      '$base/c_limit,w_512,q_auto,f_auto/v1/posts/a.jpg',
    );
  });

  test('replaces the display-time q_auto,f_auto chain', () {
    expect(
      '$base/q_auto,f_auto/v1/posts/a.jpg'.cloudinarySizedImageUrl(256),
      '$base/c_limit,w_256,q_auto,f_auto/v1/posts/a.jpg',
    );
  });

  test('leaves deliberate crops, signed, video and foreign URLs alone', () {
    final crop = '$base/c_fill,w_200,h_200,g_face/v1/a.jpg';
    final signed = '$base/s--abc--/v1/a.jpg';
    const video = 'https://res.cloudinary.com/demo/video/upload/v1/a.mp4';
    const foreign = 'https://lh3.googleusercontent.com/a/photo=s96';
    expect(crop.cloudinarySizedImageUrl(512), crop);
    expect(signed.cloudinarySizedImageUrl(512), signed);
    expect(video.cloudinarySizedImageUrl(512), video);
    expect(foreign.cloudinarySizedImageUrl(512), foreign);
  });

  test('sizes only the generated video poster chain', () {
    const poster =
        'https://res.cloudinary.com/demo/video/upload/so_0,f_jpg,q_auto/v1/a.jpg';

    expect(
      poster.cloudinarySizedVideoThumbnailUrl(256),
      'https://res.cloudinary.com/demo/video/upload/so_0,c_limit,w_256,f_jpg,q_auto/v1/a.jpg',
    );

    const other = 'https://res.cloudinary.com/demo/video/upload/v1/a.mp4';

    expect(other.cloudinarySizedVideoThumbnailUrl(256), other);
  });
}
