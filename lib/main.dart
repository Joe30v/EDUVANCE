import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AuthPage.dart';
import 'ResetPasswordPage.dart'; 
import 'LoginOTPPage.dart';

// We don't strictly need otp_state.dart for the UI flow if we use a Stateful wrapper,
// but I'll leave the import if you are using it internally.
// import 'otp_state.dart'; 

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
      navigatorKey: navigatorKey, // Important for global navigation
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
    // 1. Listen to Auth State
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // Loading...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        // 2. Not Logged In -> Show AuthPage
        if (user == null) {
          return const AuthPage();
        }

        // 3. Logged In -> Show Home (Wrapped with OTP Logic)
        // We wrap the Home page in a stateful widget to handle the 
        // "Push OTP Page" logic only once when the widget initializes.
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
    
    // ✅ PROPER NAVIGATION FIX:
    // We schedule the OTP page push after the first frame of Home renders.
    // This happens only once when this widget is created.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            // We force the OTP page to be a fullscreen modal so user can't swipe back easily
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
    // This is your Home Page UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Sign out logic
              await FirebaseAuth.instance.signOut();
              // The AuthGate stream will handle showing the AuthPage again
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'Welcome, ${widget.currentUser.email}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // CHANGE PASSWORD BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResetPasswordPage(
                      email: widget.currentUser.email ?? "",
                    ),
                  ),
                );
              },
              child: const Text(
                "Change Password",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}