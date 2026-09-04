import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  // 修正1: const ではなく final に変更 (dotenvはアプリ実行時に読み込むためconstは使えません)
  static final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  
  final SupabaseClient _supabase = Supabase.instance.client;

  // 修正2: 途中で途切れていた getAdvice メソッドを最後まで記述
  Future<String> getAdvice(String userLog) async {
    // 修正3: _apiKey という未定義の変数を _geminiApiKey に統一
    if (_geminiApiKey.isEmpty) {
      return 'APIキーが設定されていません。';
    }
    
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _geminiApiKey);
    
    final prompt = '''
    あなたは美容皮膚科医であり栄養士です。
    以下の今日のユーザーの記録をもとに、200文字以内で具体的なスキンケアと食事のアドバイスをしてください。
    【今日の記録】
    $userLog
    ''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'アドバイスの取得に失敗しました。';
    } catch (e) {
      return '通信エラーが発生しました: $e';
    }
  } // 修正4: ここに閉じカッコ } が抜けていたため、下のメソッドがエラーになっていました

  // 肌画像の解析と保存
  Future<Map<String, dynamic>> analyzeAndSaveSkinLog({
    required XFile imageFile,
    required String userId,
    String? behaviorTags,
  }) async {
    // 修正5: 'gemini-3.6-flash' というモデルは存在しないため 'gemini-1.5-flash' に修正
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final imageBytes = await File(imageFile.path).readAsBytes();
    final prompt = TextPart('''
    肌の写真を解析し、以下のJSON形式でのみ出力してください。
    {
      "skin_score": 1〜5の数値（整数）,
      "symptoms": "検出された症状（例: 赤み、乾燥、ニキビなど）"
    }
    ''');
    final imagePart = DataPart('image/jpeg', imageBytes);

    final response = await model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    final responseText = response.text ?? '{}';
    final skinScore = RegExp(r'"skin_score":\s*(\d+)').firstMatch(responseText)?.group(1) ?? '3';
    final symptoms = RegExp(r'"symptoms":\s*"([^"]+)"').firstMatch(responseText)?.group(1) ?? '特になし';

    final today = DateTime.now().toIso8601String().split('T')[0];

    // ※注意: 事前に作成したSupabaseのテーブル名は 'daily_logs' でしたが、ここでは 'skin_logs' になっています。
    // 必要に応じてテーブル名を変更してください。
    await _supabase.from('skin_logs').insert({
      'user_id': userId,
      'date': today,
      'skin_score': int.parse(skinScore),
      'symptoms': symptoms,
      'behavior_tags': behaviorTags,
    });

    return {
      'skin_score': skinScore,
      'symptoms': symptoms,
      'date': today,
    };
  }

  // 食事画像の解析
  Future<String> analyzeMealImage(XFile imageFile) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash', // こちらも修正
      apiKey: _geminiApiKey,
    );

    final imageBytes = await File(imageFile.path).readAsBytes();
    final prompt = TextPart('''
    提供された食事画像を解析し、以下の5大カテゴリ（糖質・脂質・乳製品・グルテン・刺激物）の観点から含まれている要素を箇条書きで分かりやすく抽出してください。
    語尾はレシート風の簡潔な表記にしてください。
    ''');
    final imagePart = DataPart('image/jpeg', imageBytes);

    final response = await model.generateContent([
      Content.multi([prompt, imagePart])
    ]);

    return response.text ?? '解析結果を取得できませんでした。';
  }
}