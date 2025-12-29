import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'otp_state.dart'; // Ensure you have this file created as before

class LoginOTPPage extends StatefulWidget {
  final String email;
  final String uid;

  const LoginOTPPage({
    super.key, 
    required this.email, 
    required this.uid
  });

  @override
  State<LoginOTPPage> createState() => _LoginOTPPageState();
}

class _LoginOTPPageState extends State<LoginOTPPage> {
  final _otpController = TextEditingController();
  
  String? _errorMessage;
  bool _isLoading = false;
  String? _sentOtp;

  // ------------------------------------------------------------------
  // 🔐 SENDER CONFIGURATION
  // ------------------------------------------------------------------
  final String _officialEmail = "eduvanceofficialsmartstudyapp@gmail.com";
  final String _appPassword = "xfdr gmam zqvw nzhc"; 
  // ------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // Send code automatically when entering this page
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // 1. Send OTP Email
  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    final target = widget.email.trim();
    
    if (target.isEmpty) {
      setState(() {
        _errorMessage = 'No email available to send code.';
        _isLoading = false;
      });
      return;
    }

    try {
      final otp = (Random().nextInt(9000) + 1000).toString();

      final smtpServer = gmail(_officialEmail, _appPassword);
      final message = Message()
        ..from = Address(_officialEmail, 'Eduvance Official')
        ..recipients.add(target)
        ..subject = 'Your Login Verification Code'
        ..text = 'Your verification code is: $otp\n\nIf you did not request this, please ignore this email.';

      await send(message, smtpServer);

      // Save to external state state (otp_state.dart)
      setPendingOtp(widget.uid, otp);
      _sentOtp = otp;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to $target'), 
            backgroundColor: Colors.green
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to send OTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send code. Please check your internet connection.'), 
            backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Verify OTP (The Improved Logic)
  Future<void> _verifyOtp() async {
    // Dismiss keyboard first for better UX
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      final inputOtp = _otpController.text.trim();
      
      // Check otp_state first, fallback to local state
      final expectedOtp = getPendingOtpForUid(widget.uid) ?? _sentOtp;

      // Basic Validation
      if (inputOtp.length != 4) {
        setState(() {
          _errorMessage = "Please enter the full 4-digit code.";
        });
        return;
      }

      // Comparison Logic
      if (expectedOtp != null && inputOtp == expectedOtp) {
        // ✅ SUCCESS
        
        // Clear pending OTP from state
        clearPendingOtp(widget.uid);

        if (!mounted) return;

        // Show Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Small delay to let user see the success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Pop this page to reveal the Home Page
          Navigator.of(context).pop(); 
        }

      } else {
        // ❌ FAILURE
        setState(() {
          _errorMessage = 'Invalid code. Please try again.';
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect code'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "An error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Cancel Flow
  Future<void> _cancelAndSignOut() async {
    setState(() => _isLoading = true);
    try {
      clearPendingOtp(widget.uid);
      await FirebaseAuth.instance.signOut();
      
      // Go all the way back to the first screen (AuthPage)
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
          onPressed: _cancelAndSignOut, // Back button also cancels login
        ),
      ),
      body: SingleChildScrollView( // Added scroll view for smaller screens
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 60, color: Colors.black),
            const SizedBox(height: 20),
            
            const Text('Two-step Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Enter the verification code sent to\n${widget.email}', 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                hintText: '0000',
                hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 4),
                errorText: _errorMessage,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _cancelAndSignOut,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 16, width:16, child: CircularProgressIndicator(color: Colors.white, strokeWidth:2)) 
                      : const Text('Verify', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: _isLoading ? null : _sendOtp,
              child: const Text('Didn\'t receive a code? Resend', style: TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }
}