import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';

import '/state.dart';
import '/config.dart';
import '/pages/index.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:web/web.dart' as web;

class Main extends StatelessWidget {
  AppState state;
  String? activeUrl;

  Main({required this.state, this.activeUrl, super.key});
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Inherited(notifier: state, child: router(state, activeUrl ?? AppRoutes.home)),
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //usePathUrlStrategy();
  web.window.document.querySelector(".loader")?.remove();

  KoboldApi api = KoboldApi(headers: {}, baseUrl: "http://localhost:5001");
  AppState state = AppState(api: api);

  String activeUrl = Uri.parse(web.window.location.href).path;

  runApp(Main(state: state, activeUrl: activeUrl));
}

Widget router(AppState appState, String startPage) {
  return MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'SDUI',
    routerConfig: GoRouter(
      observers: [],
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: InPaint(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ],
    ),
  );
}

var rootNavigatorKey = GlobalKey<NavigatorState>();
