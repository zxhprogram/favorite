import 'package:favorites/index_page.dart';
import 'package:favorites/pages/page1.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart' as m;

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
