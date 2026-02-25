import 'package:favorites/index_page.dart';
import 'package:favorites/pages/github_page.dart';
import 'package:favorites/pages/keystats_page.dart';
import 'package:favorites/pages/summary_page.dart';
import 'package:flutter/material.dart' as m;
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:signals/signals_flutter.dart';

import 'pages/bookmark_page.dart';
import 'pages/login_page.dart';

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
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    ShellRoute(
      builder: (context, state, child) {
        return IndexPage(childPage: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => summary_page()),
        GoRoute(
          path: '/bookmarks',
          builder: (context, state) => BookmarkPage(),
        ),
        GoRoute(path: '/github', builder: (context, state) => GithubPage()),
        GoRoute(path: '/keystats', builder: (context, state) => KeystatsPage()),
      ],
    ),
  ],
);

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
