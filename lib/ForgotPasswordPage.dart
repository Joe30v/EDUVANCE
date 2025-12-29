import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math'; 
import 'OTPPage.dart'; // Ensure this matches your file name

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // ====================================================================
  // 🔐 SENDER CONFIGURATION (Your Official Account)
  // This account acts as the "Postman" to deliver the message.
  // ====================================================================
  final String _officialEmail = "eduvanceofficialsmartstudyapp@gmail.com"; 
  final String _appPassword   = "xfdr gmam zqvw nzhc"; 
  // ====================================================================

  Future<void> _sendOtp() async {
    // 1. Validate Email Input
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // ✅ STEP 1: GET THE USER'S SPECIFIC EMAIL
    // This captures exactly what the user typed in the text box.
    final String specificUserEmail = _emailController.text.trim();

    try {
      // ✅ STEP 2: GENERATE RANDOM 4-DIGIT OTP
      String otp = (Random().nextInt(9000) + 1000).toString();

      // ✅ STEP 3: LOGIN TO YOUR OFFICIAL ACCOUNT (The Postman)
      final smtpServer = gmail(_officialEmail, _appPassword);

      // ✅ STEP 4: CREATE THE EMAIL MESSAGE
      final message = Message()
        ..from = Address(_officialEmail, 'Eduvance Official') // Name shown to user
        ..recipients.add(specificUserEmail) // <--- SEND TO THE USER HERE
        ..subject = 'Password Reset Code'
        ..text = 'Your Eduvance verification code is: $otp\n\nPlease enter this in the app to reset your password.';

      // ✅ STEP 5: SEND THE EMAIL
      await send(message, smtpServer);

      if (mounted) {
        // Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("OTP sent successfully to $specificUserEmail"),
            backgroundColor: Colors.green,
          ),
        );
        
        // ✅ STEP 6: NAVIGATE TO OTP PAGE
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPPage(
              sentOtp: otp,          // Pass the code we generated
              email: specificUserEmail // Pass the user's email
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Email Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to send email. Check internet or App Password."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text("Forgot Password", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Enter your registered email address.", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  hintText: "user@example.com",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) => (v != null && v.contains("@")) ? null : "Enter a valid email",
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Send Code", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}