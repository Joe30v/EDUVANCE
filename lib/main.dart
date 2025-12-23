import 'package:flutter/material.dart';
import 'AuthPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth UI',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Helvetica',
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Helvetica',
        ),
      ),
      home: const AuthPage(),
    );
  }
}
