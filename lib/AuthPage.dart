import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ForgotPasswordPage.dart';

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

                // TOGGLE
                Container(
                  height: 50,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(31, 129, 129, 129),
                        blurRadius: 4,
                        offset: Offset(0, 2),
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
                    if (!isLogin && pass.length < 6) return "Password must be 6+ chars";
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
                      if (v != passwordController.text) return "Passwords do not match";
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
                            
                            try {
                              if (isLogin) {
                                await FirebaseAuth.instance.signInWithEmailAndPassword(
                                  email: emailController.text.trim(),
                                  password: passwordController.text,
                                );
                              } else {
                                UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                  email: emailController.text.trim(),
                                  password: passwordController.text,
                                );
                                await cred.user?.updateDisplayName(usernameController.text.trim());
                                // We sign out so AuthGate sees the user change properly
                                await FirebaseAuth.instance.signOut();
                                if (mounted) {
                                  setState(() { isLogin = true; });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created! Please Login.")));
                                }
                              }
                            } on FirebaseAuthException catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
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
                const SizedBox(height: 30),
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