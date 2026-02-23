import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:favorites/main.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

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
      url: json['avatar'],
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

var dio = Dio(.new(baseUrl: 'http://localhost:8081'))
  ..interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: kDebugMode,
    ),
  );

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

Future<QueryAllBookmarksRes> queryAllBookmarks() async {
  if (loginInfo.value.isLogin) {
    var res = await dio.get(
      '/bookmarks',
      options: .new(
        headers: {'Authorization': 'Bearer ${loginInfo.value.token}'},
      ),
    );
    return QueryAllBookmarksRes.fromJson(res.data);
  } else {
    var res = await dio.get('/public/bookmarks');
    return QueryAllBookmarksRes.fromJson(res.data);
  }
}

class BookmarksItem {
  int id;
  String name;
  String iconUrl;
  String mimeType;
  String url;
  String description;
  String createAt;

  BookmarksItem({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.mimeType,
    required this.url,
    required this.description,
    required this.createAt,
  });

  factory BookmarksItem.fromJson(Map<String, dynamic> json) {
    // 注意：这里去掉了 .new，直接使用类名构造
    return BookmarksItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      mimeType: json['icon_mime_type'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      createAt: json['created_at'] ?? '',
    );
  }
}

class QueryAllBookmarksRes {
  bool success;
  List<BookmarksItem>? bookmarks;

  QueryAllBookmarksRes({required this.success, this.bookmarks});

  factory QueryAllBookmarksRes.fromJson(Map<String, dynamic> json) {
    return QueryAllBookmarksRes(
      success: json['success'] ?? false,
      bookmarks: json['bookmarks'] != null
          // 关键修改看这里 👇
          ? (json['bookmarks'] as List<dynamic>) // 1. 先将整体转换为 List<dynamic>
                .map(
                  (e) => BookmarksItem.fromJson(e as Map<String, dynamic>),
                ) // 2. 在 map 里对具体的 e 进行强转
                .toList()
          : [],
    );
  }
}

Future<void> createBookmark(BookmarkCreateReq req) async {
  if (!loginInfo.value.isLogin) {
    print('no login');
    return;
  }
  var r = await dio.post(
    '/bookmarks',
    data: req.toJson(),
    options: .new(
      headers: {'Authorization': 'Bearer ${loginInfo.value.token}'},
    ),
  );
  print(r.data);
}

class BookmarkCreateReq {
  String name;
  String iconUrl;
  String mimeType;
  String url;
  String? description;

  BookmarkCreateReq({
    required this.name,
    required this.iconUrl,
    required this.mimeType,
    required this.url,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon_url': iconUrl,
      'icon_mime_type': mimeType,
      'url': url,
      'description': description,
    };
  }
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
