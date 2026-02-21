import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

final mimeTypeMaps = <String, String>{
  'image/x-icon': 'icon',
  'image/svg+xml': 'svg',
  'image/png': 'png',
  'image/jpg': 'png',
  'image/jpeg': 'png',
  'image/gif': 'png',
  'image/vnd.microsoft.icon': 'icon',
};

class CaptchaRes {
  bool success;
  String captchaId;
  Uint8List image;

  CaptchaRes({
    required this.success,
    required this.captchaId,
    required this.image,
  });

  factory CaptchaRes.empty() {
    return CaptchaRes(success: true, captchaId: '-1', image: .new(0));
  }

  factory CaptchaRes.from(Map<String, dynamic> map) {
    return CaptchaRes(
      success: map['success'] as bool,
      captchaId: map['captcha_id'] as String,
      image: convert(map['image'] as String),
    );
  }

  static Uint8List convert(String base64Str) {
    base64Str = base64Str.substring('data:image/png;base64,'.length);
    return base64Decode(base64Str);
  }
}

var dio = Dio(.new(baseUrl: 'http://localhost:8081'));
Future<CaptchaRes> captchaCode() async {
  var res = await dio.get('/auth/captcha');
  return CaptchaRes.from(res.data);
}

Future<UrlInfoRes> fetchUrlInfo(String url) async {
  var response = await dio.post(
    '/urlInfo',
    data: UrlInfoReq(url: url).toJson(),
  );
  var data = response.data;
  print(data);
  return UrlInfoRes(
    success: data['success'],
    url: data['url'],
    title: data['title'],
    faviconUrl: data['favicon_url'],
    mimeType: mimeTypeMaps[data['mime_type']]!,
  );
}

class UrlInfoReq {
  String url;
  UrlInfoReq({required this.url});
  Map<String, dynamic> toJson() {
    return {'url': url};
  }
}

class UrlInfoRes {
  final bool success;
  final String url;
  final String? title;
  final String faviconUrl;
  final String mimeType;

  const UrlInfoRes({
    required this.success,
    required this.url,
    required this.faviconUrl,
    required this.mimeType,
    this.title,
  });
}
