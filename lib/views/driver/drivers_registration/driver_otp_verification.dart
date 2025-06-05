import 'package:flutter/material.dart';
import 'driver_profile_upload.dart';

class DriverOtpVerification extends StatefulWidget {
  const DriverOtpVerification({super.key});

  @override
  State<DriverOtpVerification> createState() => _DriverOtpVerificationState();
}

class _DriverOtpVerificationState extends State<DriverOtpVerification> {
  bool isOTPStage = false;
  TextEditingController phoneController = TextEditingController();
  List<TextEditingController> otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );

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
                    'assets/images/driver_registration.png',
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

          // Body content below header
          Positioned.fill(
            top: 220,
            child: Center(
              child: isOTPStage ? buildVerifyOtpCard() : buildPhoneInputCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPhoneInputCard() {
    return cardWrapper(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phone_android, size: 80, color: Colors.deepOrange),
          const SizedBox(height: 10),
          const Text(
            'Enter your mobile number to create account.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter mobile number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isOTPStage = true;
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

  Widget buildVerifyOtpCard() {
    return cardWrapper(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user, size: 80, color: Colors.orange),
          const SizedBox(height: 10),
          const Text(
            'Mobile verification has successfully done',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'We have sent the OTP on ${phoneController.text.isNotEmpty ? phoneController.text : "your number"}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (index) => SizedBox(
                width: 40,
                child: TextField(
                  controller: otpControllers[index],
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "If you didn’t receive a code! Resend",
            style: TextStyle(fontSize: 12, color: Colors.blue),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverProfileUpload(),
                ),
              );
            },
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      margin: const EdgeInsets.all(20),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}
