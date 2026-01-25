import 'package:flutter/foundation.dart';
import 'dart:convert' as convert;
import 'dart:async';
import 'package:http/http.dart' as http;

class ServerUnreachableException implements Exception {
  final String message;
  ServerUnreachableException(this.message);
}

class AppException implements Exception {
  final String message;
  AppException(this.message);
}

class FaultyRequestException implements Exception {
  final String message;

  FaultyRequestException(this.message);

  factory FaultyRequestException.fromJson(Map<String, dynamic> json) {
    return FaultyRequestException(json['message'] ?? 'Unexpected error');
  }
}

class BadRequestException implements Exception {
  final String message;

  BadRequestException(this.message);

  factory BadRequestException.fromJson(Map<String, dynamic> json) {
    return BadRequestException(json['message'] ?? 'Unexpected error');
  }
}

class UnAuthorizedException implements Exception {
  final String message;
  UnAuthorizedException(this.message);
}

const commonHeaders = {"Content-Type": "application/json"};

class Server {
  Map<String, String> headers;
  String baseUrl;
  ByteData? sslCertificate;
  final Function(Exception error)? onError;
  http.Client client = http.Client();
  Server({required this.headers, required this.baseUrl, this.sslCertificate, this.onError});

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    var request = await client.post(
      Uri.parse(baseUrl + path),
      headers: {...commonHeaders, ...headers},
      body: convert.jsonEncode(body),
    );

    Exception exception = ServerUnreachableException('Unexpected server error');
    switch (request.statusCode) {
      case 200 || 201 || 204:
        {
          try {
            if (request.body.contains("ok: false")) {
              exception = FaultyRequestException(convert.jsonDecode(request.body)["message"] ?? 'Unexpected error');
            } else {
              return convert.jsonDecode(request.body);
            }
          } catch (err) {}
        }
      case 400:
        exception = BadRequestException('Unexpected error');
      case 401 || 403:
        exception = UnAuthorizedException('Unauthorized access');
      case 502:
        exception = ServerUnreachableException('Server is unreachable');
    }
    if (onError != null) {
      throw onError!(exception);
    } else {
      throw exception;
    }
  }

  Future<dynamic> get(String path) async {
    var request = await client.get(Uri.parse(baseUrl + path), headers: {...commonHeaders, ...headers});

    Exception exception = ServerUnreachableException('Unexpected server error');
    switch (request.statusCode) {
      case 200 || 201 || 204:
        {
          try {
            var data = convert.jsonDecode(request.body);
            if (data.toString().contains("ok: false") || data.toString().contains("success: false")) {
              exception = FaultyRequestException(data["message"] ?? 'Unexpected error');
            } else {
              return data;
            }
          } catch (err) {}
        }
      case 400:
        exception = BadRequestException('Unexpected error');
      case 401 || 403:
        exception = UnAuthorizedException('Unauthorized access');
      case 502:
        exception = ServerUnreachableException('Server is unreachable');
    }
    if (onError != null) {
      throw onError!(exception);
    } else {
      throw exception;
    }
  }

  // Future<dynamic> testExpired() async {
  //   onError!(UnAuthorizedException('Unauthorized access'));
  // }
}

Future<void> waitForServerReady(Future<dynamic> Function() requestFactory, {int maxRetries = 50}) async {
  for (var i = 0; i < maxRetries; i++) {
    try {
      await requestFactory();
      return; // Success - server is back up
    } catch (e) {
      if (i == maxRetries - 1) rethrow; // Give up after max retries
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
