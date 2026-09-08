import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // 🔑 iOSで非同期処理を行うために必須の記述
  WidgetsFlutterBinding.ensureInitialized();

  // 🔑 .env の読み込みエラーで白画面停止しないよう try-catch で保護
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(".env の読み込みに失敗しました: $e");
  }

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B9AC4)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}