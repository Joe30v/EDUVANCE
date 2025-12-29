import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AuthPage.dart';
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
      title: 'Task Master',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto', 
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
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
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // --- ERROR FIXED HERE (removed 'const') ---
          return AuthPage(); 
        }

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
  bool _isVerified = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startVerification());
  }

  Future<void> _startVerification() async {
    try {
      await widget.currentUser.reload(); 
    } catch (e) {
      debugPrint("Error reloading user: $e");
    }

    if (!mounted) return;

    final bool? result = await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true, 
        builder: (_) => LoginOTPPage(
          email: widget.currentUser.email ?? '', 
          uid: widget.currentUser.uid
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        _isVerified = true;
      });
    } else {
      if (FirebaseAuth.instance.currentUser != null) {
         await FirebaseAuth.instance.signOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerified) {
      return DashboardPage(user: FirebaseAuth.instance.currentUser ?? widget.currentUser);
    }
    
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );
  }
}