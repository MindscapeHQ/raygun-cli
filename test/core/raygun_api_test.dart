import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:raygun_cli/src/core/raygun_api.dart';
import 'package:test/test.dart';

void main() {
  group('RaygunMultipartRequestBuilder', () {
    const url = 'https://app.raygun.com/upload';

    test('parses the URL and HTTP method into the underlying request', () {
      final req = RaygunMultipartRequestBuilder(url, 'POST').build();
      expect(req.method, 'POST');
      expect(req.url, Uri.parse(url));
    });

    test('supports non-POST methods (e.g. PUT)', () {
      final req = RaygunMultipartRequestBuilder(url, 'PUT').build();
      expect(req.method, 'PUT');
    });

    test('addBearerToken adds an Authorization header', () {
      final req = RaygunMultipartRequestBuilder(
        url,
        'POST',
      ).addBearerToken('abc123').build();
      expect(req.headers['Authorization'], 'Bearer abc123');
    });

    test('addField stores key-value pairs in fields', () {
      final req = RaygunMultipartRequestBuilder(
        url,
        'POST',
      ).addField('version', '1.2.3').addField('owner', 'alice').build();
      expect(req.fields['version'], '1.2.3');
      expect(req.fields['owner'], 'alice');
    });

    test('addFile attaches a file when it exists', () {
      final tempDir = Directory.systemTemp.createTempSync('raygun_api_test_');
      try {
        final filePath = p.join(tempDir.path, 'mapping.txt');
        File(filePath).writeAsStringSync('hello world');

        final req = RaygunMultipartRequestBuilder(
          url,
          'POST',
        ).addFile('mapping', filePath).build();

        expect(req.files, hasLength(1));
        expect(req.files.single.field, 'mapping');
        expect(req.files.single.length, 'hello world'.length);
        // Filename is the basename — last segment after splitting on `/`.
        expect(req.files.single.filename, 'mapping.txt');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('addFile throws Exception when the file does not exist', () {
      expect(
        () => RaygunMultipartRequestBuilder(
          url,
          'POST',
        ).addFile('mapping', '/tmp/definitely_not_here_xyz123.txt'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('File not found'),
          ),
        ),
      );
    });

    test('builder methods return the same instance for chaining', () {
      final builder = RaygunMultipartRequestBuilder(url, 'POST');
      expect(identical(builder.addBearerToken('t'), builder), isTrue);
      expect(identical(builder.addField('k', 'v'), builder), isTrue);
    });

    test('build returns the same MultipartRequest on multiple calls', () {
      final builder = RaygunMultipartRequestBuilder(url, 'POST');
      final r1 = builder.build();
      final r2 = builder.build();
      expect(identical(r1, r2), isTrue);
    });

    test('multiple addField calls accumulate fields', () {
      final req = RaygunMultipartRequestBuilder(
        url,
        'POST',
      ).addField('a', '1').addField('b', '2').addField('c', '3').build();
      expect(req.fields, {'a': '1', 'b': '2', 'c': '3'});
    });

    test('addField overwrites a previous value for the same key', () {
      final req = RaygunMultipartRequestBuilder(
        url,
        'POST',
      ).addField('version', '1.0.0').addField('version', '2.0.0').build();
      expect(req.fields['version'], '2.0.0');
    });
  });

  group('RaygunPostRequestBuilder', () {
    const url = 'https://app.raygun.com/v3/deployments';

    test('parses the URL and uses POST method', () {
      final req = RaygunPostRequestBuilder(url).build();
      expect(req.method, 'POST');
      expect(req.url, Uri.parse(url));
    });

    test('addBearerToken adds an Authorization header', () {
      final req = RaygunPostRequestBuilder(
        url,
      ).addBearerToken('xyz789').build();
      expect(req.headers['Authorization'], 'Bearer xyz789');
    });

    test('addJsonBody serializes the body to JSON and sets Content-Type', () {
      final req = RaygunPostRequestBuilder(
        url,
      ).addJsonBody({'version': '1.2.3', 'owner': 'alice'}).build();
      expect(req.headers['Content-Type'], 'application/json');
      expect(jsonDecode(req.body), {'version': '1.2.3', 'owner': 'alice'});
    });

    test('addJsonBody handles nested structures', () {
      final body = {
        'version': '1.0.0',
        'meta': {
          'env': 'prod',
          'tags': ['a', 'b'],
        },
      };
      final req = RaygunPostRequestBuilder(url).addJsonBody(body).build();
      expect(jsonDecode(req.body), body);
    });

    test('addJsonBody handles an empty map', () {
      final req = RaygunPostRequestBuilder(url).addJsonBody({}).build();
      expect(req.body, '{}');
      expect(req.headers['Content-Type'], 'application/json');
    });

    test('builder methods return the same instance for chaining', () {
      final builder = RaygunPostRequestBuilder(url);
      expect(identical(builder.addBearerToken('t'), builder), isTrue);
      expect(identical(builder.addJsonBody({'k': 'v'}), builder), isTrue);
    });

    test('build returns the same Request on multiple calls', () {
      final builder = RaygunPostRequestBuilder(url);
      final r1 = builder.build();
      final r2 = builder.build();
      expect(identical(r1, r2), isTrue);
    });

    test('chained: bearer + JSON body produces both header and body', () {
      final req = RaygunPostRequestBuilder(
        url,
      ).addBearerToken('tok').addJsonBody({'version': '1.0.0'}).build();
      expect(req.headers['Authorization'], 'Bearer tok');
      expect(req.headers['Content-Type'], 'application/json');
      expect(jsonDecode(req.body), {'version': '1.0.0'});
    });
  });
}
