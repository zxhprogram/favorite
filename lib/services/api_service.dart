import 'package:dio/dio.dart';

final mimeTypeMaps = <String, String>{
  'image/x-icon': 'icon',
  'image/svg+xml': 'svg',
  'image/png': 'png',
  'image/jpg': 'png',
  'image/jpeg': 'png',
  'image/gif': 'png',
  'image/vnd.microsoft.icon': 'icon',
};

Future<UrlInfoRes> fetchUrlInfo(String url) async {
  var dio = Dio();
  var response = await dio.post(
    'http://localhost:8081/urlInfo',
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
