import 'package:cached_network_image/cached_network_image.dart';
import 'package:favorites/index_page.dart';
import 'package:favorites/pages/page1.dart';
import 'package:favorites/services/api_service.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart' as m;
import 'package:signals/signals_flutter.dart';

void main() {
  runApp(
    ShadcnApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: routers,
      materialTheme: m.ThemeData(fontFamily: 'firacodenerdfont'),
    ),
  );
}

final routers = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => Page3()),
    ShellRoute(
      builder: (context, state, child) {
        return IndexPage(childPage: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => Page1()),
        GoRoute(path: '/page2', builder: (context, state) => Page2()),
      ],
    ),
  ],
);

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('page2'));
  }
}

class Page3 extends StatefulWidget {
  @override
  State<Page3> createState() => _Page3State();
}

class _Page3State extends State<Page3> {
  var captchaState = signal<CaptchaRes>(CaptchaRes.empty());
  var isLoading = signal<bool>(true);

  @override
  void initState() {
    super.initState();
    handleData();
  }

  Future<void> handleData() async {
    isLoading.value = true; // 开始 loading
    try {
      var r = await captchaCode();
      captchaState.value = CaptchaRes(
        captchaId: r.captchaId,
        success: r.success,
        image: r.image,
      );
    } finally {
      isLoading.value = false; // 结束 loading
    }
  }

  @override
  Widget build(BuildContext context) {
    var rr = captchaState.watch(context);
    var loading = isLoading.watch(context);

    return Scaffold(
      child: Row(
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1770110000218-e9376e581258?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
            ),
          ),
          Container(
            width: 350,
            margin: const EdgeInsets.all(20), // 规范化语法
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UI Unicorn'),
                const Text('Nice to see you again'),
                const Text('Login'),
                const TextField(placeholder: Text('Email or phone number')),
                const Text('Password'),
                const TextField(
                  placeholder: Text('Enter password'),
                  features: [.passwordToggle(mode: .hold)],
                ),
                const Text('captcha'),

                // 5. 彻底移除 FutureBuilder，直接通过我们 watch 到的状态来渲染！
                if (loading)
                  const SizedBox(
                    width: 100,
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 50,
                        // 直接从状态 rr 中读取图片
                        child: Image.memory(rr.image),
                      ),
                      Button.card(
                        child: const Icon(Icons.refresh),
                        onPressed: () {
                          // 6. 点击刷新时，直接调用封装好的 handleData 即可！
                          handleData();
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
