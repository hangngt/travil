import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/services/auth_service.dart';
import 'main_navigation.dart';
import 'auth/login_screen.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.currentUser == null) {
      return const LoginScreen();
    }
    return const MainNavigation();
  }
}
