import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'views/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[400],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Image.asset(
                'assets/splashScreen/Safe_Ride_SplashScreen.jpg',
                height: 500,
                width: 500,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 30),
            Positioned(
              bottom: 10,
              child: Lottie.asset(
                'assets/splashScreen/sakaynaLoading_animation.json',
                width: 250,
                height: 250,
                repeat: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
