import 'package:flutter/material.dart';
import 'passenger_final_credentials.dart';

class PassengerMobileVerification extends StatefulWidget {
  final Map<String, dynamic> basicInfo;

  const PassengerMobileVerification({super.key, required this.basicInfo});

  @override
  State<PassengerMobileVerification> createState() =>
      _PassengerMobileVerificationState();
}

class _PassengerMobileVerificationState
    extends State<PassengerMobileVerification> {
  bool isOTPStage = false;
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _verifyOTP() {
    // Here you would typically verify the OTP with your backend
    // For now, we'll just proceed to the next screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PassengerFinalCredentials(
              basicInfo: widget.basicInfo,
              phoneNumber: _phoneController.text.trim(),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      body: Stack(
        children: [
          // Top semi-circle header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 254, 255, 255),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(200),
                  bottomRight: Radius.circular(200),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/passenger_registrationbg.png',
                    height: 100,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Mobile Verification",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Main card below the header
          Positioned.fill(
            top: 220,
            child: Center(
              child:
                  isOTPStage
                      ? buildVerifyAccountCard()
                      : buildCreateAccountCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCreateAccountCard() {
    return cardWrapper(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sms, size: 80, color: Colors.deepOrange),
          const SizedBox(height: 10),
          const Text(
            'Enter your mobile number to create account.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter mobile number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              if (_phoneController.text.isEmpty) {
                setState(() {
                  _errorMessage = 'Please enter your phone number';
                });
                return;
              }
              setState(() {
                isOTPStage = true;
                _errorMessage = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget buildVerifyAccountCard() {
    return cardWrapper(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Colors.deepOrange),
          const SizedBox(height: 10),
          const Text(
            'Enter the verification code sent to your phone.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (index) => SizedBox(
                width: 50,
                child: TextField(
                  controller: _otpControllers[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _verifyOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget cardWrapper(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}
