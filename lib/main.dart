import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/auth_service.dart';
import 'viewmodel/home_viewmodel.dart';
import 'viewmodel/calendar_viewmodel.dart';
import 'viewmodel/stats_viewmodel.dart';
import 'viewmodel/willgo_viewmodel.dart';
import 'views/rootscreen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("STEP 1");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("STEP 2");

  runApp(const MyApp());

  print("STEP 3");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        //  lazy init để tránh block startup
        ChangeNotifierProvider(create: (_) => AuthService(), lazy: true),
        ChangeNotifierProvider(create: (_) => HomeViewModel(), lazy: true),
        ChangeNotifierProvider(create: (_) => CalendarViewModel(), lazy: true),
        ChangeNotifierProvider(create: (_) => StatsViewModel(), lazy: true),
        ChangeNotifierProvider(create: (_) => WillGoViewModel(), lazy: true),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Travel Recommendation',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const RootScreen(),
      ),
    );
  }
}
