import 'package:flutter/material.dart';
import 'ResetPasswordPage.dart'; // Make sure you have this page created

class OTPPage extends StatefulWidget {
  final String sentOtp; // The code from the email
  final String email;   // The user's email

  const OTPPage({
    super.key, 
    required this.sentOtp, 
    required this.email
  });

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final _otpController = TextEditingController();
  String? _errorMessage;

  void _verifyOtp() {
    // Compare input with the code sent via email
    if (_otpController.text.trim() == widget.sentOtp) {
      // Success: Go to Reset Password
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(email: widget.email),
        ),
      );
    } else {
      // Failure
      setState(() {
        _errorMessage = "Invalid code. Please check your email.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Verification", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Enter the 4-digit code sent to ${widget.email}"),
            const SizedBox(height: 40),
            
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              decoration: InputDecoration(
                counterText: "",
                hintText: "0000",
                errorText: _errorMessage,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
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
                onPressed: _verifyOtp,
                child: const Text("Verify", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}