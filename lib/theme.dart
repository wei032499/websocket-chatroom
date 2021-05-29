import 'package:flutter/material.dart';

class AppTheme {
  //
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    colorScheme: ColorScheme.light()
  );

  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.dark()
  );
}
