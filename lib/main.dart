import 'package:favorites/index_page.dart';
import 'package:favorites/pages/summary_page.dart';
import 'package:favorites/pages/page3.dart';
import 'package:flutter/material.dart' as m;
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
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
        GoRoute(path: '/', builder: (context, state) => summary_page()),
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

final loginInfo = signal<LoginInfo>(.new(isLogin: false));

class LoginInfo {
  String? currentUserName;
  String? currentUserAvatar;
  bool isLogin;
  String? token;

  LoginInfo({
    required this.isLogin,
    this.token,
    this.currentUserName,
    this.currentUserAvatar,
  });
}
