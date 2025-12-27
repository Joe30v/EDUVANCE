import 'package:flutter/material.dart';

class OTPPage extends StatefulWidget {
  final String? email;
  const OTPPage({super.key, this.email});

  @override
  State<OTPPage> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OTPPage> {
  // 1. Controllers for the 4 input fields
  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());

  // 2. Focus nodes to handle automatic focus shifting
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  // 3. State variable to track error status
  bool _isError = false;

  @override
  void dispose() {
    for (var controller in _controllers) controller.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }

  // Logic to handle input changes
  void _onChanged(String value, int index) {
    // Reset error state when user types
    if (_isError) {
      setState(() {
        _isError = false;
      });
    }

    // Move to next field if value is entered
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    // Move to previous field if value is deleted (optional UX improvement)
    else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  // Logic to validate on Submit
  void _onSubmit() {
    // Check if any field is empty
    bool anyEmpty = _controllers.any((controller) => controller.text.isEmpty);

    setState(() {
      _isError = anyEmpty;
    });

    if (!_isError) {
      // PROCEED WITH AUTHENTICATION
      final otp = _controllers.map((c) => c.text).join();
      print("OTP Validated: $otp");
      // For now we won't navigate to a dashboard; show confirmation and stay on screen
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP validated (dashboard not implemented)')));
    } else {
      // CLEAR FIELDS FOR ERROR VISUAL (Optional - matches the right image)
      for (var controller in _controllers) controller.clear();
      // Unfocus keyboard
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Cancel Button (Top Right)
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              
              // --- Title ---
              const Text(
                "One Time Password",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // --- Subtitle ---
Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  // Show email if provided
                  widget.email != null && widget.email!.isNotEmpty
                      ? "We have sent an OTP to ${widget.email}"
                      : "We have sent OTP code verification to your Email Address",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- Illustration Placeholder ---
              // Ideally, use Image.asset('assets/otp_illustration.png') here
              Container(
                height: 180,
                width: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.laptop_mac_rounded, // Placeholder icon
                  size: 80,
                  color: Colors.grey.shade400,
                ),
              ),

              const SizedBox(height: 40),

              // --- OTP Input Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      // Toggle color based on error state
                      color: _isError 
                          ? const Color(0xFFFF8A8A) // Light Red (Error)
                          : const Color(0xFFF2F2F2), // Light Grey (Normal)
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!_isError)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      onChanged: (value) => _onChanged(value, index),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: "", // Hides the counter
                      ),
                    ),
                  );
                }),
              ),

              // --- Error Message ---
              if (_isError) ...[
                const SizedBox(height: 16),
                const Text(
                  "OTP is Required",
                  style: TextStyle(
                    color: Colors.red, // Using standard red or specific #FF0000
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Submit",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- Resend Link ---
              GestureDetector(
                onTap: () {
                  // Resend logic here
                  print("Resend OTP clicked");
                },
                child: const Text(
                  "Resend OTP",
                  style: TextStyle(
                    color: Color(0xFFC0C0C0), // Light grey text
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}