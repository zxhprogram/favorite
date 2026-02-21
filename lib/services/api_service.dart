import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:favorites/main.dart';
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

class UploadAvatarRes {
  bool success;
  String url;
  String message;

  UploadAvatarRes({
    required this.success,
    required this.url,
    required this.message,
  });

  factory UploadAvatarRes.fromJson(Map<String, dynamic> json) {
    return .new(
      success: json['success'],
      url: json['url'],
      message: json['message'],
    );
  }
}

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

class LoginReq {
  String email;
  String password;
  String captchaId;
  String captchaCode;

  LoginReq({
    required this.email,
    required this.password,
    required this.captchaId,
    required this.captchaCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'captcha_id': captchaId,
      'captcha_code': captchaCode,
    };
  }
}

Future<UploadAvatarRes> uploadAvatar(File file) async {
  MultipartFile multipartFile = await MultipartFile.fromFile(
    file.path,
    filename: file.path.split('/').last,
  );
  var form = FormData.fromMap({'file': multipartFile});
  var r = await dio.post(
    '/user/avatar',
    data: form,
    options: .new(
      headers: {'Authorization': 'Bearer ${loginInfo.value.token}'},
    ),
  );
  print(r.data);
  return .fromJson(r.data);
}

Future<LoginRes> login(LoginReq req) async {
  var r = await dio.post('/auth/login', data: req.toJson());
  if (r.statusCode != 200) {
    return .failLogin();
  }
  print('login -> ${r.data}');
  return .fromJson(r.data);
}

class LoginRes {
  bool success;
  String token;
  String? nickname;
  String message;
  String? avatar;

  LoginRes({
    required this.success,
    required this.token,
    required this.message,
    this.nickname,
    this.avatar,
  });

  factory LoginRes.fromJson(Map<String, dynamic> map) {
    return .new(
      success: map['success'] as bool,
      token: map['token'] as String,
      nickname: map['nickname'] as String?,
      message: map['message'] as String,
      avatar: map['avatar'] as String?,
    );
  }

  factory LoginRes.failLogin() {
    return LoginRes(success: false, token: '', message: '');
  }
}

Future<void> createAccount(CreateAccountReq req) async {
  var r = await dio.post('/auth/register', data: req.toJson());
  print(r.data);
}

class CreateAccountReq {
  String email;
  String password;
  String nickname;
  String captchaId;
  String captchaCode;

  CreateAccountReq({
    required this.email,
    required this.password,
    required this.nickname,
    required this.captchaId,
    required this.captchaCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'nickname': nickname,
      'password': password,
      'captcha_id': captchaId,
      'captcha_code': captchaCode,
    };
  }
}

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
