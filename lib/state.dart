import 'dart:convert';

import 'package:flutter/material.dart';
import '/services/api.dart';
import 'components/painter.dart';
import 'package:localstorage/localstorage.dart';
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
  AppState({required this.api});

  KoboldApi? api;
  List<BackgroundImage> images = [];

  Future<void> loadImageCache() async {
    String? data = localStorage.getItem("image_cache");
    if (data != null) images = jsonDecode(data).map((item) => BackgroundImage.fromJson(item));
    notifyListeners();
  }

  void saveImageCache() async {
    localStorage.setItem("image_cache", jsonEncode(List.from(images.map((image) => image.toJson()))));
  }

  void addImage(BackgroundImage image) {
    images.add(image);
    saveImageCache();
    notifyListeners();
  }
}
