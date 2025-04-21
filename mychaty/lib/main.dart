import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mychaty/Auth/Authenticate.dart';
import 'package:mychaty/firebase_options.dart';

import 'Auth/LoginScreen.dart';

Future main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Authenticate(),
    );
  }
}

