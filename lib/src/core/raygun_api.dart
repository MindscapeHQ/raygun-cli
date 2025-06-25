import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

class RaygunMultipartRequestBuilder {
  late final MultipartRequest _request;

  RaygunMultipartRequestBuilder(String url, String requestType) {
    _request = MultipartRequest(requestType, Uri.parse(url));
  }

  RaygunMultipartRequestBuilder addBearerToken(String token) {
    _request.headers['Authorization'] = 'Bearer $token';
    return this;
  }

  RaygunMultipartRequestBuilder addFile(String field, String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File not found: $filePath');
    }
    _request.files.add(
      MultipartFile(
        field,
        file.readAsBytes().asStream(),
        file.lengthSync(),
        filename: filePath.split("/").last,
      ),
    );

    return this;
  }

  RaygunMultipartRequestBuilder addField(String field, String value) {
    _request.fields[field] = value;
    return this;
  }

  MultipartRequest build() {
    return _request;
  }
}

class RaygunPostRequestBuilder {
  late final Request _request;

  RaygunPostRequestBuilder(String url) {
    _request = Request('POST', Uri.parse(url));
  }

  RaygunPostRequestBuilder addBearerToken(String token) {
    _request.headers['Authorization'] = 'Bearer $token';
    return this;
  }

  RaygunPostRequestBuilder addJsonBody(Map<String, dynamic> body) {
    _request.body = jsonEncode(body);
    _request.headers['Content-Type'] = 'application/json';
    return this;
  }

  Request build() {
    return _request;
  }
}
