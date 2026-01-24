import 'package:flutter/material.dart';

const supportedLanguages = ['en', 'de'];

const itemsOnPage = 15;

class AppRoutes {
  static const home = '/';
  static const folders = '/folders';
  static const folder = '/folder/:name';
}

class _AppColors {
  static const white = Colors.white;
  static const black = Color(0xFF111B1D);
  static const green = Color(0xFF0EBB49);
  static const red = Colors.red;
  static const primary = Color.fromRGBO(250, 172, 39, 1);
  static const secondary = Color(0xFFFFFFFF);
}

ThemeData appThemeData = ThemeData(
  fontFamily: "Roboto",
  useMaterial3: true,

  datePickerTheme: const DatePickerThemeData(
    headerBackgroundColor: Color.fromRGBO(204, 198, 192, 1),
    backgroundColor: Color.fromRGBO(249, 251, 255, 1),
    headerForegroundColor: _AppColors.white,
    surfaceTintColor: Color.fromRGBO(204, 198, 192, 1),
    dayStyle: TextStyle(fontSize: 16, color: Colors.black),
  ),
  colorScheme: ColorScheme.fromSeed(
    primary: const Color.fromRGBO(249, 251, 255, 1),
    secondary: const Color.fromRGBO(243, 245, 251, 1),
    tertiary: const Color.fromRGBO(119, 120, 120, 1),
    error: _AppColors.red,
    onPrimary: _AppColors.white, // titles and
    onSurface: _AppColors.black,
    seedColor: _AppColors.white,
    shadow: const Color.fromRGBO(236, 240, 241, 1.0),
    brightness: Brightness.dark,
    surface: const Color.fromRGBO(243, 245, 251, 1),
  ),
  canvasColor: Colors.white,
  highlightColor: const Color.fromRGBO(116, 185, 255, 1.0),
  scaffoldBackgroundColor: Colors.white,
  unselectedWidgetColor: Colors.white,
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color(0xFF111B1D),
    selectionColor: Color(0x40777878),
    selectionHandleColor: Color(0xFF777878),
  ),
  textButtonTheme: TextButtonThemeData(style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.blueAccent))),
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 22, color: _AppColors.black, fontFamily: "Roboto"),
    displayMedium: TextStyle(fontSize: 16, color: _AppColors.black, fontFamily: "Roboto"),
    displaySmall: TextStyle(fontSize: 13, color: _AppColors.black, fontFamily: "Roboto"),
    titleLarge: TextStyle(fontSize: 38, color: _AppColors.black, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(fontSize: 25, color: _AppColors.black, fontWeight: FontWeight.bold),
    titleSmall: TextStyle(fontSize: 19, color: _AppColors.black, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(fontSize: 19, color: _AppColors.black),
    bodyMedium: TextStyle(fontSize: 16, color: _AppColors.black),
    bodySmall: TextStyle(fontSize: 14, color: _AppColors.black),
    labelLarge: TextStyle(fontSize: 19, color: _AppColors.black),
    labelMedium: TextStyle(fontSize: 16, color: _AppColors.black),
    labelSmall: TextStyle(fontSize: 14, color: _AppColors.black),
  ),
  scrollbarTheme: ScrollbarThemeData(thumbVisibility: WidgetStateProperty.all<bool>(true)),
  dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
  inputDecorationTheme: InputDecorationTheme(
    labelStyle: TextStyle(fontSize: 16, color: _AppColors.black, fontFamily: "Roboto"),
    fillColor: Colors.white,
    border: UnderlineInputBorder(borderRadius: BorderRadius.zero),
    enabledBorder: UnderlineInputBorder(borderRadius: BorderRadius.zero),
    focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.zero),
    errorBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: UnderlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: const BorderSide(color: Colors.red, width: 2),
    ),
  ),
);
