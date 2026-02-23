import 'dart:io';

import 'package:dio/dio.dart';
import 'package:favorites/main.dart';
import 'package:favorites/models/api.dart';
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
  return .fromJson(r.data);
}

Future<LoginRes> login(LoginReq req) async {
  var r = await dio.post('/auth/login', data: req.toJson());
  if (r.statusCode != 200) {
    return .failLogin();
  }
  return .fromJson(r.data);
}

Future<void> createAccount(CreateAccountReq req) async {
  var r = await dio.post('/auth/register', data: req.toJson());
}

Future<CaptchaRes> captchaCode() async {
  var res = await dio.get('/auth/captcha');
  return CaptchaRes.from(res.data);
}

Future<void> sortBookmarks(SortBookmarksRequest req) async {
  var r = await dio.post(
    '/bookmarks/sort',
    data: req.toJson(),
    options: .new(
      headers: {'Authorization': 'Bearer ${loginInfo.value.token}'},
    ),
  );
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

Future<void> createBookmark(BookmarkCreateReq req) async {
  if (!loginInfo.value.isLogin) {
    return;
  }
  var r = await dio.post(
    '/bookmarks',
    data: req.toJson(),
    options: .new(
      headers: {'Authorization': 'Bearer ${loginInfo.value.token}'},
    ),
  );
}

Future<UrlInfoRes> fetchUrlInfo(String url) async {
  var response = await dio.post(
    '/urlInfo',
    data: UrlInfoReq(url: url).toJson(),
  );
  var data = response.data;
  return UrlInfoRes(
    success: data['success'],
    url: data['url'],
    title: data['title'],
    faviconUrl: data['favicon_url'],
    mimeType: mimeTypeMaps[data['mime_type']]!,
  );
}
