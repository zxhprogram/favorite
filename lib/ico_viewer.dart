import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class IcoViewer extends StatefulWidget {
  final String url; // 支持网络链接或本地 asset 路径

  const IcoViewer({super.key, required this.url});

  @override
  State<IcoViewer> createState() => _IcoViewerState();
}

class _IcoViewerState extends State<IcoViewer> {
  Future<Uint8List>? _icoFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _icoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (snapshot.hasError) {
          // 加载或解析失败时显示默认错误图标
          return const Icon(Icons.broken_image, color: Colors.grey);
        } else if (snapshot.hasData) {
          // 4. 使用 Image.memory 直接渲染内存中的 PNG 字节流
          return Image.memory(
            snapshot.data!,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _icoFuture = _loadAndConvertIco(widget.url);
  }

  // 核心逻辑：加载并转换 ICO 为 PNG 字节
  Future<Uint8List> _loadAndConvertIco(String path) async {
    Uint8List icoBytes;

    // 1. 获取 ICO 文件的原始字节（区分网络和本地资源）
    if (path.startsWith('http')) {
      final response = await http.get(Uri.parse(path));
      icoBytes = response.bodyBytes;
    } else {
      final ByteData data = await rootBundle.load(path);
      icoBytes = data.buffer.asUint8List();
    }

    return await Isolate.run(() {
      // decodeImage 会自动识别各种格式（包括 ico）
      final img.Image? decodedImage = img.decodeImage(icoBytes);

      if (decodedImage == null) {
        throw Exception('无法解码该 ICO 图片');
      }

      // 【核心修复点 👇】
      // 检查该图片是否包含多个帧（多尺寸）
      img.Image targetFrame = decodedImage;
      if (decodedImage.numFrames > 1) {
        // 如果有多帧，我们强行只提取第一帧（或者根据你的需求提取最大尺寸的一帧）
        // 这样可以彻底剥离它的“动画/多帧”属性
        targetFrame = decodedImage.frames.first;
      }

      // 3. 将单帧图片重新编码为 Flutter 支持的单张 PNG 字节
      // 添加 singleFrame: true 参数，确保绝对不会生成 APNG（动态 PNG）
      return img.encodePng(targetFrame, singleFrame: true);
    });
  }
}
