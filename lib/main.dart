import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'AuthPage.dart'; // Ensure this matches your file name exactly

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    debugPrint('Firebase initialization error: $e\n$st');
  }

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // If Firebase isn't initialized, show the login page directly (or an error screen)
    if (Firebase.apps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auth (No Firebase)')),
        body: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Firebase is not configured. Add platform config files.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              AuthPage(),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        // 2. User is NOT logged in -> Show Login/Signup Page
        if (user == null) {
          return const AuthPage();
        }

        // 3. User IS logged in -> Show Home Page with Sign Out button
        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            backgroundColor: Colors.white, // Explicitly set background to white
            elevation: 0, // Remove shadow for cleaner look
            actions: [
              TextButton(
                onPressed: () async => await FirebaseAuth.instance.signOut(),
                // *** FIX IS HERE: Changed color to Black ***
                child: const Text('Sign out', style: TextStyle(color: Colors.black)),
              )
            ],
          ),
          body: Center(
            child: Text('Signed in as ${user.email ?? user.uid}'),
          ),
        );
      },
    );
  }
}