import 'package:flutter_test/flutter_test.dart';
import 'package:nagarsevak_mobile/data/models/complaint_model.dart';
import 'package:nagarsevak_mobile/core/services/supabase_service.dart';

void main() {
  group('ComplaintAttachment & Image parsing tests', () {
    test('isImage handles query params and various extensions', () {
      final att1 = ComplaintAttachment(
        url: 'https://example.com/photo.JPG?width=200&token=xyz',
        type: 'image/jpeg',
        name: 'Photo 1',
      );
      expect(att1.isImage, isTrue);

      final att2 = ComplaintAttachment(
        url: 'https://example.com/photo.webp',
        type: 'application/octet-stream',
        name: 'Photo 2',
      );
      expect(att2.isImage, isTrue);

      final att3 = ComplaintAttachment(
        url: 'https://example.com/document.pdf?dl=1',
        type: 'application/pdf',
        name: 'Doc',
      );
      expect(att3.isImage, isFalse);
      expect(att3.isPdf, isTrue);
    });

    test('ComplaintModel.fromJson parses string attachments and image_url', () {
      final json = {
        'id': 'test-123',
        'title': 'Broken road',
        'description': 'Potholes on main street',
        'category': 'Roads',
        'status': 'Pending',
        'image_url': 'https://example.com/main.png',
        'photos': ['https://example.com/p1.jpg', 'https://example.com/p2.jpg'],
        'attachments': [
          {'url': 'https://example.com/att1.jpg', 'type': 'image/jpeg'},
          'https://example.com/att2.png',
        ],
        'created_at': DateTime.now().toIso8601String(),
      };

      final model = ComplaintModel.fromJson(json);
      expect(model.imageUrl, 'https://example.com/main.png');
      expect(model.photos.length, 3); // includes image_url and 2 photos
      expect(model.attachments.length, 2);
      expect(model.attachments[0].url, 'https://example.com/att1.jpg');
      expect(model.attachments[1].url, 'https://example.com/att2.png');
    });

    test('resolveStorageUrl resolves storage paths accurately', () {
      final service = SupabaseService.instance;

      // Full URL stays untouched
      expect(
        service.resolveStorageUrl('https://example.com/test.jpg'),
        'https://example.com/test.jpg',
      );

      // Relative path with documents prefix
      final docUrl = service.resolveStorageUrl('documents/complaints/test.jpg');
      expect(docUrl.contains('/documents/complaints/test.jpg'), isTrue);

      // Relative path with complaints/
      final compUrl = service.resolveStorageUrl('tenant-1/complaints/photo.jpg');
      expect(compUrl.contains('/documents/tenant-1/complaints/photo.jpg'), isTrue);
    });
  });
}
