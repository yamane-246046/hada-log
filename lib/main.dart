import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 追加

Future<void> main() async {
  // アプリ起動前に .env を読み込む
  await dotenv.load(fileName: ".env"); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hada-Log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A7C59)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      ),
      home: const HomeScreen(),
    );
  }
}