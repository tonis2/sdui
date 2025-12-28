import 'package:hive_ce/hive_ce.dart';
import 'package:flutter/material.dart';
import '/services/api.dart';

export '/services/api.dart';
import '/models/index.dart';

class Inherited extends InheritedNotifier<AppState> {
  const Inherited({required super.child, super.key, required super.notifier});
  static AppState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Inherited>()!.notifier;
  }

  @override
  bool updateShouldNotify(InheritedNotifier<AppState> oldState) => true;
}

Future<AppState> createState({required KoboldApi api}) async {
  Hive.registerAdapter(ImageAdapter());
  var images = await Hive.openBox<BackgroundImage>('images');
  return AppState(api: api, images: images);
}

class AppState extends ChangeNotifier {
  AppState({required this.api, required this.images});

  KoboldApi api;
  Box<BackgroundImage> images;
}
