import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ForgotPasswordPage.dart';
// import 'otp_state.dart'; // Not strictly needed here

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool rememberMe = false;
  bool _isLoading = false; 

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.black),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color.fromARGB(255, 255, 17, 0)),
      ),
    );
  }

  // ✅ HELPER FUNCTION: Translates Firebase errors to user-friendly text
  String _getFriendlyErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'invalid-email':
        return 'The email address format is invalid. Please check for typos.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many login attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'credential-already-in-use':
        return 'This email is already associated with another account.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'An unexpected error occurred ($errorCode). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  isLogin ? "Login Account" : "Sign up now",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isLogin
                      ? "Hello, Welcome back to your account."
                      : "Create a free account",
                  style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                /// TOGGLE
                Container(
                  height: 50,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(31, 129, 129, 129),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      toggleButton("Sign Up", !isLogin),
                      toggleButton("Login", isLogin),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                if (!isLogin) ...[
                  const Text("Username", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: usernameController,
                    decoration: inputDecoration("Enter Username"),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Username is Required" : null,
                  ),
                  const SizedBox(height: 16),
                ],

                const Text("Email Address", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: inputDecoration("Enter Email Address"),
                  validator: (v) {
                    final email = v?.trim() ?? '';
                    if (email.isEmpty) return "Email Address is Required";
                    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
                    if (!emailRegex.hasMatch(email)) return "Enter a valid email address";
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                const Text("Password", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  obscureText: true,
                  decoration: inputDecoration("Enter Password"),
                  validator: (v) {
                    final pass = v ?? '';
                    if (pass.isEmpty) return "Password is Required";
                    if (!isLogin) {
                      final strongRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$');
                      if (!strongRegex.hasMatch(pass)) {
                        return "Password must be 8+ chars with upper, lower, number & special char";
                      }
                    }
                    return null;
                  },
                ),

                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  const Text("Confirm Password", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: confirmPasswordController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    obscureText: true,
                    decoration: inputDecoration("Re-enter Password"),
                    validator: (v) {
                      final pass = v ?? '';
                      if (pass.isEmpty) return "Password is Required";
                      if (pass != passwordController.text) return "Passwords do not match";
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                if (isLogin)
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (v) => setState(() => rememberMe = v!),
                      ),
                      const Text("Keep me signed in", style: TextStyle(fontSize: 14)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _isLoading
                        ? null 
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            setState(() => _isLoading = true);

                            final email = emailController.text.trim();
                            final password = passwordController.text;

                            if (isLogin) {
                              // --- LOGIN LOGIC ---
                              try {
                                await FirebaseAuth.instance.signInWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );
                                // Success! Main.dart stream will detect this and launch OTP page.
                              } on FirebaseAuthException catch (e) {
                                if (!mounted) return;
                                
                                // ✅ FIXED: Use friendly error message
                                String errorMessage = _getFriendlyErrorMessage(e.code);

                                showDialog<void>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Login Failed'),
                                    content: Text(errorMessage),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('OK', style: TextStyle(color: Colors.black)),
                                      )
                                    ],
                                  ),
                                );
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            } else {
                              // --- SIGN UP LOGIC ---
                              try {
                                UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );

                                // ✅ SAVE USERNAME
                                await userCred.user?.updateDisplayName(usernameController.text.trim());

                                // Sign out so they have to login explicitly
                                await FirebaseAuth.instance.signOut();

                                if (!mounted) return;
                                setState(() {
                                  isLogin = true;
                                  _formKey.currentState?.reset();
                                });
                                usernameController.clear();
                                emailController.clear();
                                passwordController.clear();
                                confirmPasswordController.clear();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Account created successfully. Please log in.')),
                                );
                              } on FirebaseAuthException catch (e) {
                                if (e.code == 'email-already-in-use') {
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ForgotPasswordPage(),
                                    ),
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Email already in use — opened Forgot Password page.')),
                                  );
                                } else {
                                  // ✅ FIXED: Use friendly error message for generic sign-up errors too
                                  if (!mounted) return;
                                  String errorMessage = _getFriendlyErrorMessage(e.code);

                                  showDialog<void>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Sign Up Failed'),
                                      content: Text(errorMessage),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('OK', style: TextStyle(color: Colors.black)),
                                        )
                                      ],
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isLogin ? "Login" : "Sign Up",
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget toggleButton(String text, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isLogin = (text == "Login");
            _formKey.currentState?.reset();
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}