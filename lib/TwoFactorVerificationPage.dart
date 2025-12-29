import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'HomePage.dart'; // ✅ Ensure this points to your Home Page

class TwoFactorVerificationPage extends StatefulWidget {
  final String sentOtp;
  final String userEmail;
  final String userPassword; // ✅ Needed to perform the final login

  const TwoFactorVerificationPage({
    super.key, 
    required this.sentOtp, 
    required this.userEmail,
    required this.userPassword,
  });

  @override
  State<TwoFactorVerificationPage> createState() => _TwoFactorVerificationPageState();
}

class _TwoFactorVerificationPageState extends State<TwoFactorVerificationPage> {
  final _otpController = TextEditingController();
  String? _errorMessage;
  bool _isValidating = false;

  Future<void> _verifyAndLogin() async {
    // 1. Check if OTP matches
    if (_otpController.text.trim() == widget.sentOtp) {
      
      setState(() => _isValidating = true);

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: widget.userEmail,
          password: widget.userPassword,
        );

        // 3. Navigate to Home
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false, 
          );
        }

      } on FirebaseAuthException catch (e) {
        setState(() {
          _isValidating = false;
          _errorMessage = "Login failed: ${e.message}";
        });
      }

    } else {
      setState(() {
        _errorMessage = "Incorrect code. Please check your email.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Two-Factor Auth"), elevation: 0, backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.security, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text("Verification Required", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "We sent a code to ${widget.userEmail}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // OTP Field
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              decoration: InputDecoration(
                counterText: "",
                hintText: "0000",
                errorText: _errorMessage,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: _isValidating ? null : _verifyAndLogin,
                child: _isValidating 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Verify & Enter", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}