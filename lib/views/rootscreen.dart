import 'package:flutter/material.dart';
import 'package:joggapp/data/services/auth_service.dart';
import 'package:joggapp/views/home.dart';
import 'package:joggapp/views/loginscreen.dart';
import 'package:provider/provider.dart';

// màn hình điều hướng theo trạng thái đăng nhập
// Kiểm tra user đã đăng nhập chưa
class Rootscreen extends StatelessWidget {
  const Rootscreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.user == null) {
      return const LoginScreen();
    }a
    return const Homescreen();
  }
}
