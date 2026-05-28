import 'dart:async';
import 'package:flutter/material.dart';
import 'package:joggapp/core/color.dart';
import 'package:joggapp/views/rootscreen.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  void initState() {
    super.initState();

    // Chờ 5 giây rồi chuyển màn hình
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Rootscreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.primary,
      body: SizedBox.expand(
        child: Image.asset("images/onboarding.png", fit: BoxFit.cover),
      ),
    );
  }
}
