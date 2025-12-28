import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';
import 'menu.dart';

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
  AppState state = AppState(api: api);

  runApp(Main(state: state));
}

Widget base(Widget child) {
  // Size size = MediaQuery.sizeOf(rootNavigatorKey.currentState!.context);
  return Expanded(
    child: Column(
      spacing: 10,
      children: [
        SizedBox(width: 200, height: 70, child: Menu()),
        Expanded(child: child),
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
