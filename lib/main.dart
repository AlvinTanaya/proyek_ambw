import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:proyek_ambw/screens/signin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyC5fzmV29n8LOCdB-RqqSZvoOYYYHae8Gw',
        appId: '1:613767812470:android:05c552579615e536ae1657',
        messagingSenderId: '613767812470',
        projectId: 'proyek-ambw',
        storageBucket: 'proyek-ambw.appspot.com',
      ),
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SignInScreen(),
    );
  }
}
