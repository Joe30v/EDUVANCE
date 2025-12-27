import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ForgotPasswordPage.dart';
import 'OTPPage.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool rememberMe = false;

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
                          style: TextStyle(color: Colors.grey,fontSize: 14),
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
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final email = emailController.text.trim();
                      final password = passwordController.text;

                      if (isLogin) {
                        try {
                          await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: email,
                            password: password,
                          );
                          if (!mounted) return;
                          // Navigate to OTP page to complete secondary verification
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OTPPage(email: email)),
                          );
                        } on FirebaseAuthException catch (e) {
                          if (!mounted) return;
                          showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Login failed'),
                              content: Text(e.message ?? 'Unable to sign in'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                )
                              ],
                            ),
                          );
                        }
                      } else {
                        try {
                          await FirebaseAuth.instance.createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                          // After creating the account, sign the user out so they must explicitly
                          // log in, then switch the UI to the Login view immediately.
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
                            // Open Forgot Password page so the user can reset via email.
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
                            showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Sign up failed'),
                                content: Text(e.message ?? 'Unable to create account'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  )
                                ],
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Text(isLogin ? "Login" : "Sign Up"),
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
