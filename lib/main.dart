import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AuthPage.dart';
import 'ResetPasswordPage.dart'; 
import 'LoginOTPPage.dart';
import 'DashboardPage.dart'; 

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
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
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        if (user == null) {
          return const AuthPage();
        }

        // Logged In -> Show Home Wrapper
        return HomeWrapper(currentUser: user);
      },
    );
  }
}

class HomeWrapper extends StatefulWidget {
  final User currentUser;
  const HomeWrapper({super.key, required this.currentUser});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  // Start as false so the Dashboard is HIDDEN initially
  bool _isVerified = false; 

  @override
  void initState() {
    super.initState();
    // Schedule the OTP page push immediately
    WidgetsBinding.instance.addPostFrameCallback((_) => _startVerification());
  }

  Future<void> _startVerification() async {
    if (!mounted) return;

    // Push the OTP Page and WAIT for a result (true/false)
    final bool? result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true, 
        builder: (_) => LoginOTPPage(
          email: widget.currentUser.email ?? '', 
          uid: widget.currentUser.uid
        ),
      ),
    );

    // If result is true, it means verification was successful
    if (result == true && mounted) {
      setState(() {
        _isVerified = true;
      });
    } else {
      // If they cancelled or backed out, sign them out so they go back to Login
      if (FirebaseAuth.instance.currentUser != null) {
         await FirebaseAuth.instance.signOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. If verified, show the Dashboard
    if (_isVerified) {
      return DashboardPage(user: widget.currentUser);
    }
    
    // 2. Otherwise, show a plain white loading screen (hides the dashboard)
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );
  }
}