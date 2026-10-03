import 'package:flutter/material.dart';
import 'screens/anatomy_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AnatomyApp());
}

class AnatomyApp extends StatelessWidget {
  const AnatomyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenasni Kamel Professeur Anatomy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4AA3FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF070B11),
        useMaterial3: true,
      ),
      home: const AnatomyHome(),
    );
  }
}
