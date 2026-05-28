import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:joggapp/data/responsive/run_responsitory.dart';
// import 'package:joggapp/data/services/auth_service.dart';
// import 'package:joggapp/viewmodel/home_map.dart';
// import 'package:joggapp/viewmodel/run_viewmodel.dart';
// import 'package:joggapp/viewmodel/stats_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:travil/views/onboarding.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // ChangeNotifierProvider(create: (_) => AuthService()),
        // ChangeNotifierProvider(create: (_) => HomeMap()..init()),
        // ChangeNotifierProvider(create: (_) => RunViewModel()),
        // ChangeNotifierProvider(create: (_) => StatsViewModel()),
        // ChangeNotifierProvider(create: (_) => RunRepository()..loadRuns()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Onboarding(),
      debugShowCheckedModeBanner: false,
    );
  }
}
