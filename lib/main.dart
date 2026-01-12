import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:localstorage/localstorage.dart';
import 'package:sdui/pages/node_editor/index.dart';
import 'menu.dart';
import 'dart:ui';
import '/state.dart';
import '/config.dart';
import '/pages/index.dart';

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

var rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalStorage();
  //usePathUrlStrategy();
  // web.window.document.querySelector(".loader")?.remove();

  KoboldApi api = KoboldApi(headers: {}, baseUrl: "http://localhost:5001");
  AppState state = await createState(api: api);

  runApp(Main(state: state));
}

Widget base(Widget child) {
  // Size size = MediaQuery.sizeOf(rootNavigatorKey.currentState!.context);
  FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
  return SizedBox(
    width: view.physicalSize.width,
    height: view.physicalSize.height,
    child: Stack(
      children: [
        Expanded(child: child),
        SizedBox(width: 400, height: 70, child: Menu()),
      ],
    ),
  );
}

Widget router(AppState appState, String startPage) {
  return MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'SDUI',
    routerConfig: GoRouter(
      navigatorKey: rootNavigatorKey,
      observers: [],
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: base(GenerateImage()),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.nodes,
          pageBuilder: (context, state) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: base(NodeEditor()),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.gallery,
          pageBuilder: (context, state) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: base(Gallery()),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ],
    ),
  );
}
