import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AuthPage.dart';
import 'ResetPasswordPage.dart'; 
import 'LoginOTPPage.dart';
import 'DashboardPage.dart'; // <--- THIS IMPORT WAS MISSING

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

        // Logged In -> Show Home (Wrapped with OTP Logic)
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
  @override
  void initState() {
    super.initState();
    
    // Push the OTP page on top of the Dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true, 
            builder: (_) => LoginOTPPage(
              email: widget.currentUser.email ?? '', 
              uid: widget.currentUser.uid
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show the Dashboard underneath the OTP popup
    return DashboardPage(user: widget.currentUser);
  }
}