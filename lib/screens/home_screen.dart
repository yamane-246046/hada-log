import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Gemini SDK

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ⚠️ ここに取得したGemini APIキーを設定してください
  static const String _geminiApiKey = 'YOUR_API_KEY_HERE';

  DateTime _selectedDate = DateTime.now();
  int _selectedCondition = 3; // 1〜5 (デフォルト: 普通 3)
  
  final Set<String> _selectedSymptoms = {'乾燥'};
  
  final TextEditingController _breakfastController = TextEditingController(text: 'トースト、目玉焼き、コーヒー');
  final TextEditingController _lunchController = TextEditingController(text: 'パスタ、サイドサラダ');
  final TextEditingController _dinnerController = TextEditingController(text: '焼き魚定食、味噌汁');
  final TextEditingController _memoController = TextEditingController(text: '今日は少し乾燥している気がする。');

  // 画像ファイル保持用変数
  XFile? _breakfastImage;
  XFile? _lunchImage;
  XFile? _dinnerImage;
  XFile? _skinImage;

  final ImagePicker _picker = ImagePicker();

  final List<String> _symptomList = ['乾燥', '赤み', 'ニキビ', 'かゆみ', 'べたつき'];
  final List<String> _conditionEmojis = ['😫', '🙁', '😐', '🙂', '😊'];

  @override
  void dispose() {
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // --- Gemini AI 解析処理 ---
  Future<void> _analyzeWithGemini() async {
    if (_geminiApiKey == 'YOUR_API_KEY_HERE' || _geminiApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('APIキーが設定されていません。コードにGemini APIキーを入力してください。')),
      );
      return;
    }

    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Gemini AIが肌状態と食事を解析中...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // モデルの設定
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );

      // プロンプト（指示文）の組み立て
      final promptText = '''
あなたは優秀な皮膚科医および管理栄養士です。
以下の記録（肌状態、自覚症状、食事、メモ）と添付画像を総合的に分析し、ユーザーに対する肌アドバイスを作成してください。

【本日のログ】
- 日付: ${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}
- 本人の実感コンディション: ${_conditionEmojis[_selectedCondition - 1]} (5段階中 $_selectedCondition)
- 気になる症状: ${_selectedSymptoms.join(', ')}
- 朝食: ${_breakfastController.text}
- 昼食: ${_lunchController.text}
- 夕食: ${_dinnerController.text}
- 自由メモ: ${_memoController.text}

【出力フォーマット】
1. **肌の状態診断**: 写真と選択された症状から推測される現状
2. **食事評価**: 肌に対する栄養バランスの分析
3. **今日のおすすめアドバイス**: 具体的なスキンケアや食生活の提案
親しみやすく分かりやすい日本語で回答してください。
''';

      final List<Content> contentParts = [];
      final List<Part> parts = [TextPart(promptText)];

      // 肌写真があれば追加
      if (_skinImage != null) {
        final skinImageBytes = await File(_skinImage!.path).readAsBytes();
        parts.add(DataPart('image/jpeg', skinImageBytes));
      }

      // 食事写真があれば追加
      if (_breakfastImage != null) {
        final bytes = await File(_breakfastImage!.path).readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }
      if (_lunchImage != null) {
        final bytes = await File(_lunchImage!.path).readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }
      if (_dinnerImage != null) {
        final bytes = await File(_dinnerImage!.path).readAsBytes();
        parts.add(DataPart('image/jpeg', bytes));
      }

      contentParts.add(Content.multi(parts));

      // Geminiにリクエスト送信
      final response = await model.generateContent(contentParts);

      if (mounted) {
        Navigator.pop(context); // ローディング消去
        _showResultDialog(response.text ?? '解析結果を取得できませんでした。');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ローディング消去
        _showResultDialog('エラーが発生しました:\n$e');
      }
    }
  }

  // AI解析結果表示ダイアログ
  void _showResultDialog(String resultText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF6B9AC4)),
              SizedBox(width: 8),
              Text('AI肌解析結果', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(resultText, style: const TextStyle(height: 1.5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // 画像取得処理（カメラ or ギャラリー）
  Future<void> _pickImage(ImageSource source, Function(XFile) onSelected) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          onSelected(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像の選択に失敗しました: $e')),
        );
      }
    }
  }

  // カメラ・アルバム選択モーダル
  void _showImagePickerModal(Function(XFile) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF4A7C59)),
                title: const Text('カメラで撮影'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, onSelected);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF4A7C59)),
                title: const Text('アルバムから選択'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, onSelected);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFullCalendarModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FullCalendarModal(
        initialDate: _selectedDate,
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Hada-Log',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D576B),
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF4A7C59), size: 22),
              ),
              onPressed: _openFullCalendarModal,
              tooltip: '全画面表示カレンダー',
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付表示
            Text(
              '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 肌調子（絵文字選択）
            const Text('今日の肌調子', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_conditionEmojis.length, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCondition = index + 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedCondition == index + 1 ? Colors.blue.shade100 : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _conditionEmojis[index],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // 症状の選択
            const Text('気になる症状', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _symptomList.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 食事ログ
            const Text('食事ログ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildMealInputRow('朝食', _breakfastController, _breakfastImage, (img) => _breakfastImage = img),
            const SizedBox(height: 8),
            _buildMealInputRow('昼食', _lunchController, _lunchImage, (img) => _lunchImage = img),
            const SizedBox(height: 8),
            _buildMealInputRow('夕食', _dinnerController, _dinnerImage, (img) => _dinnerImage = img),
            const SizedBox(height: 20),

            // 自由メモ & 肌写真
            const Text('自由メモ・肌写真', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'メモを入力',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // 肌写真撮影エリア
            GestureDetector(
              onTap: () => _showImagePickerModal((img) => _skinImage = img),
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _skinImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_skinImage!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, color: Color(0xFF4A7C59), size: 30),
                          SizedBox(height: 4),
                          Text(
                            'AI解析用の肌写真を撮影・選択',
                            style: TextStyle(color: Color(0xFF4A7C59), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // 保存・解析ボタン（Gemini AI呼出に接続）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _analyzeWithGemini,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text('保存してAI解析', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF6B9AC4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealInputRow(String label, TextEditingController controller, XFile? image, Function(XFile) onSelected) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showImagePickerModal(onSelected),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4A7C59)),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.camera_alt, color: Color(0xFF4A7C59)),
          ),
        ),
      ],
    );
  }
}

class FullCalendarModal extends StatelessWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const FullCalendarModal({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ),
    );
  }
}