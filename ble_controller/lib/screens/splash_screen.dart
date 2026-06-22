import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/control');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔷 LOGO PRINCIPAL (centro)
          Center(child: Image.asset('assets/logo.png', width: 150)),

          // 👤 LOGO DEV (abajo)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(child: Image.asset('assets/dev.png', width: 150)),
          ),
        ],
      ),
    );
  }
}
