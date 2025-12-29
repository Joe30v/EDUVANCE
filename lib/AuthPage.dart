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
      filled: true,
      fillColor: Colors.grey.shade50,
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
        borderSide: const BorderSide(color: Colors.red),
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

                // TOGGLE BUTTON
                Container(
                  height: 50,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      toggleButton("Sign Up", !isLogin),
                      toggleButton("Login", isLogin),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // USERNAME FIELD (Only for Sign Up)
                if (!isLogin) ...[
                  const Text("Username", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: usernameController,
                    decoration: inputDecoration("Enter Username"),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Username is Required" : null,
                  ),
                  const SizedBox(height: 16),
                ],

                const Text("Email Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: inputDecoration("Enter Email Address"),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Email is Required";
                    if (!v.contains('@')) return "Enter a valid email";
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                const Text("Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  obscureText: true,
                  decoration: inputDecoration("Enter Password"),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Password is Required";
                    if (!isLogin && v.length < 6) return "Password must be 6+ chars";
                    return null;
                  },
                ),

                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  const Text("Confirm Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                        activeColor: Colors.black,
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
                          style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
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
                                // LOGIN LOGIC
                                await FirebaseAuth.instance.signInWithEmailAndPassword(
                                  email: emailController.text.trim(),
                                  password: passwordController.text,
                                );
                              } else {
                                // SIGN UP LOGIC
                                UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                  email: emailController.text.trim(),
                                  password: passwordController.text,
                                );
                                
                                // CRITICAL: Save the username!
                                await cred.user?.updateDisplayName(usernameController.text.trim());
                                await cred.user?.reload(); // Refresh to ensure it's saved locally

                                // Sign out so they can log in fresh (triggers proper data load)
                                await FirebaseAuth.instance.signOut();
                                
                                if (mounted) {
                                  setState(() { 
                                    isLogin = true; 
                                    _formKey.currentState?.reset();
                                    usernameController.clear();
                                    emailController.clear();
                                    passwordController.clear();
                                    confirmPasswordController.clear();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Account Created Successfully! Please Login."))
                                  );
                                }
                              }
                            } on FirebaseAuthException catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message ?? "Authentication Error"))
                              );
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isLogin ? "Login" : "Sign Up",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
            boxShadow: selected ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2)
              )
            ] : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}