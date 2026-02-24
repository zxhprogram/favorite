import 'dart:convert';

import 'package:flutter/foundation.dart';

class GithubTrendingReq {
  String? language;
  String? since;

  GithubTrendingReq({this.language, this.since});

  Map<String, dynamic> toJson() {
    return {'language': language, 'since': since};
  }
}

class GithubTrendingRes {
  bool success;
  List<Repository> repositories;

  GithubTrendingRes({required this.success, required this.repositories});

  factory GithubTrendingRes.fromJson(Map<String, dynamic> json) {
    return .new(
      success: json['success'],
      repositories: (json['repositories'] as List<dynamic>)
          .map((e) => Repository.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Repository {
  String author;
  String name;
  String avatar;
  String url;
  String? description;
  String language;
  String languageColor;
  int stars;
  int forks;
  List<BuildBy>? buildBy;

  Repository({
    required this.author,
    required this.name,
    required this.avatar,
    required this.url,
    this.description,
    required this.language,
    required this.languageColor,
    required this.stars,
    required this.forks,
    this.buildBy,
  });

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      author: json['author'],
      name: json['name'],
      avatar: json['avatar'],
      url: json['url'],
      language: json['language'],
      languageColor: json['languageColor'],
      stars: json['stars'],
      forks: json['forks'],
      buildBy: json['buildBy'] == null
          ? null
          : (json['buildBy'] as List<dynamic>)
                .map((e) => BuildBy.fromJson(e as Map<String, dynamic>))
                .toList(),
    );
  }
}

class BuildBy {
  String username;
  String href;
  String avatar;

  BuildBy({required this.username, required this.href, required this.avatar});

  factory BuildBy.fromJson(Map<String, dynamic> json) {
    return .new(
      username: json['username'],
      href: json['href'],
      avatar: json['avatar'],
    );
  }
}

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

class SortBookmarksRequest {
  List<SortItem> bookmarks;

  SortBookmarksRequest({required this.bookmarks});

  Map<String, dynamic> toJson() {
    return {'bookmarks': bookmarks.map((e) => e.toJson()).toList()};
  }
}

class SortItem {
  int id;
  int sortOrder;

  SortItem({required this.id, required this.sortOrder});

  Map<String, dynamic> toJson() {
    return {'id': id, 'sort_order': sortOrder};
  }
}

class BookmarksItem {
  final int id;
  final String name;
  final String iconUrl;
  final String mimeType;
  final String url;
  final String description;
  final String createAt;
  final int? folderId;

  const BookmarksItem({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.mimeType,
    required this.url,
    required this.description,
    required this.createAt,
    this.folderId,
  });

  factory BookmarksItem.fromJson(Map<String, dynamic> json) {
    return BookmarksItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      mimeType: json['icon_mime_type'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      createAt: json['created_at'] ?? '',
      folderId: json['folder_id'],
    );
  }

  @override
  String toString() {
    return '{id:$id,name:$name,iconUrl=$iconUrl,mimeType:$mimeType,url:$url,description:$description,createdAt:$createAt}';
  }
}

class QueryAllBookmarksRes {
  final bool success;
  final List<BookmarksItem>? bookmarks;

  const QueryAllBookmarksRes({required this.success, this.bookmarks});

  factory QueryAllBookmarksRes.fromJson(Map<String, dynamic> json) {
    return QueryAllBookmarksRes(
      success: json['success'] ?? false,
      bookmarks: json['bookmarks'] != null
          ? (json['bookmarks'] as List<dynamic>)
                .map((e) => BookmarksItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
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

class FolderItem {
  final int id;
  final String name;
  final int sortOrder;
  final String createdAt;

  const FolderItem({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
  });

  factory FolderItem.fromJson(Map<String, dynamic> json) {
    return FolderItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class QueryAllFoldersRes {
  final bool success;
  final List<FolderItem>? folders;

  const QueryAllFoldersRes({required this.success, this.folders});

  factory QueryAllFoldersRes.fromJson(Map<String, dynamic> json) {
    return QueryAllFoldersRes(
      success: json['success'] ?? false,
      folders: json['folders'] != null
          ? (json['folders'] as List<dynamic>)
                .map((e) => FolderItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
    );
  }
}

class CreateFolderReq {
  final String name;

  const CreateFolderReq({required this.name});

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class MoveBookmarkToFolderReq {
  final int bookmarkId;
  final int? folderId;

  const MoveBookmarkToFolderReq({required this.bookmarkId, this.folderId});

  Map<String, dynamic> toJson() {
    return {'bookmark_id': bookmarkId, 'folder_id': folderId};
  }
}
