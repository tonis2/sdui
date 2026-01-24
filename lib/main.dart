import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/services/pwa/pwa_install.dart';
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
    return Directionality(
      textDirection: .ltr,
      child: Material(
        child: Inherited(notifier: state, child: router(state)),
      ),
    );
  }
}

var rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize PWA install service for web
  PwaInstallService().init();
  AppState state = await createState();
  runApp(Main(state: state));
}

Widget queueView(BuildContext context) {
  AppState provider = Inherited.of(context)!;
  ThemeData theme = Theme.of(context);
  return Positioned(
    top: 20,
    right: 20,
    child: Container(
      width: 300,
      height: 600,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color.fromRGBO(212, 212, 212, 0.5)),
      child: SingleChildScrollView(
        child: Column(
          spacing: 10,
          mainAxisSize: .min,
          mainAxisAlignment: .start,
          crossAxisAlignment: .start,
          children: provider.promptQueue.map((item) {
            MemoryImage? image;

            if (item.image != null) {
              image = MemoryImage(item.image!);
            }

            return SizedBox(
              width: 350,
              child: Row(
                mainAxisSize: .min,
                mainAxisAlignment: .start,
                crossAxisAlignment: .start,
                spacing: 10,
                children: [
                  if (image != null) Image(image: ResizeImage(image, width: 60, height: 60)),
                  Column(
                    mainAxisSize: .min,
                    spacing: 5,
                    children: [
                      if (item.startTime == null) Text("Item in queue", style: theme.textTheme.bodySmall),
                      if (item.startTime != null)
                        Text(
                          "Start time: ${item.startTime.toString().split(" ")[1]}",
                          style: theme.textTheme.bodySmall,
                        ),
                      if (item.endTime != null)
                        Text("End time: ${item.endTime.toString().split(" ")[1]}", style: theme.textTheme.bodySmall),
                      if (item.endTime != null && item.startTime != null)
                        Text(
                          "Time spent: ${item.endTime!.difference(item.startTime!).toString().split(".")[0]}",
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      provider.promptQueue.retainWhere((item) => item.endTime == null);
                      provider.update();
                    },
                    child: Icon(Icons.delete_forever, color: theme.colorScheme.tertiary),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}

Widget base(Widget child, BuildContext context) {
  AppState? provider = Inherited.of(context);
  ThemeData theme = Theme.of(context);
  FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;

  return Container(
    decoration: BoxDecoration(color: theme.colorScheme.primary),
    width: view.physicalSize.width,
    height: view.physicalSize.height,
    child: Stack(
      children: [
        SizedBox(width: view.physicalSize.width, height: view.physicalSize.height, child: child),
        Positioned(width: 70, height: view.physicalSize.height, child: Menu()),
        if (provider != null && provider.promptQueue.isNotEmpty) queueView(context),
      ],
    ),
  );
}

Widget router(AppState appState) {
  return MaterialApp.router(
    debugShowCheckedModeBanner: false,
    title: 'SDUI',
    theme: appThemeData,
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
              child: base(NodeEditor(), context),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.folder,
          pageBuilder: (context, state) {
            String? name = state.pathParameters["name"];

            if (name == null) {
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: Text("Folder not found"),
                transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
              );
            }

            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: base(FolderView(path: name), context),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.folders,
          pageBuilder: (context, state) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: base(Folders(), context),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ],
    ),
  );
}
