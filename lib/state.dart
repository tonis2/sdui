import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '/services/api.dart';
export '/services/api.dart';

class Inherited extends InheritedNotifier<AppState> {
  const Inherited({required super.child, super.key, required super.notifier});
  static AppState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Inherited>()!.notifier;
  }

  @override
  bool updateShouldNotify(InheritedNotifier<AppState> oldState) => true;
}

class AppState extends ChangeNotifier {
  KoboldApi? api;
  AppState({required this.api});
}
