import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Need 'http' in pubspec.yaml
import 'dart:convert';
import 'dart:io'; // To detect Android vs iOS

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    // ---------------------------------------------------------
    // 🔗 CONNECT TO YOUR LOCAL NODE.JS SERVER
    // ---------------------------------------------------------
    // If you are using a real phone, replace this with your laptop's IP or Ngrok URL
    // Example: 'http://192.168.1.5:3000/reset-password'
    String serverUrl = Platform.isAndroid 
        ? 'http://10.0.2.2:3000/reset-password' 
        : 'http://localhost:3000/reset-password';
    // ---------------------------------------------------------

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'newPassword': _passController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
         // ✅ Success
         await showDialog(
           context: context,
           barrierDismissible: false,
           builder: (_) => AlertDialog(
             title: const Text("Success"),
             content: const Text("Password updated successfully!"),
             actions: [
               TextButton(
                 onPressed: () {
                   Navigator.pop(context);
                   Navigator.popUntil(context, (route) => route.isFirst); // Go back to Login
                 },
                 child: const Text("Login Now"),
               )
             ],
           ),
         );
      } else {
         // ❌ Server Error (e.g., user not found)
         final errorData = jsonDecode(response.body);
         throw Exception(errorData['error'] ?? "Unknown Error");
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Connection Error"),
          content: Text("Could not connect to the backend.\n\nMake sure your Node.js server is running!\n\nDetails: $e"),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Set New Password"), 
        backgroundColor: Colors.white, 
        elevation: 0, 
        foregroundColor: Colors.black
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Create a strong new password for your account.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // New Password Field
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                validator: (v) => v!.length < 6 ? "Password must be at least 6 characters" : null,
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                validator: (v) => v != _passController.text ? "Passwords do not match" : null,
              ),
              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _isLoading ? null : _updatePassword,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Update Password", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}