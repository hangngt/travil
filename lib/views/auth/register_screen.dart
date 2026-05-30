import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:travil/core/color.dart';
import 'package:travil/data/services/auth_service.dart';

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  final _formkey =
      GlobalKey<
        FormState
      >(); //kiểm tra xem tất cả các ô nhập liệu có hợp lệ hay không
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formkey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      await context.read<AuthService>().register(
        _name.text.trim(),
        _email.text.trim(),
        _pass.text.trim(),
      );
      String message = "Signup success. Please click Login";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/home");
      }
    } on FirebaseAuthException catch (e) {
      String message = "Signup failed";

      // if (e.code == 'email-already-in-use') {
      //   message = "Email already exists";
      // } else if (e.code == 'invalid-email') {
      //   message = "Invalid email";
      // } else if (e.code == 'weak-password') {
      //   message = "Password too weak";
      // }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        //mounted là một biến có sẵn trong State của Flutter
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: TColor.bgcard,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: size.height * 0.3,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/signup.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: keyboard),

              child: Column(
                children: [
                  SizedBox(height: size.height * 0.24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: TColor.bgcard,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formkey,

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Create Account",

                            style: TextStyle(
                              color: TColor.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 26),
                          TextFormField(
                            decoration: InputDecoration(
                              hint: Text("Name"),
                              icon: Icon(Icons.person_outlined),
                            ),
                            controller: _name,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Name required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _email,
                            decoration: InputDecoration(
                              hint: Text("Email"),
                              icon: Icon(Icons.email_outlined),
                            ),

                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Email required';
                              if (!s.contains('@')) return 'Enter valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _pass,
                            decoration: InputDecoration(
                              hint: Text("Password"),
                              icon: Icon(Icons.key_outlined),
                            ),
                            obscureText: true,
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return 'Password required';
                              if (s.length < 6) return 'Min 6 chars';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.btncolor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.circular(
                                    14,
                                  ),
                                ),
                              ),
                              child:
                                  _loading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text(
                                        " Sign Up",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Already have an account?"),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: TColor.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
