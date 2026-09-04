import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SkinLogScreen extends StatefulWidget {
  const SkinLogScreen({super.key});

  @override
  State<SkinLogScreen> createState() => _SkinLogScreenState();
}

class _SkinLogScreenState extends State<SkinLogScreen> {
  XFile? _breakfastImage;
  XFile? _lunchImage;
  XFile? _dinnerImage;
  XFile? _skinImage;

  final ImagePicker _picker = ImagePicker();

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
          SnackBar(content: Text('画像取得エラー: $e')),
        );
      }
    }
  }

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
                leading: const Icon(Icons.camera_alt, color: Colors.teal),
                title: const Text('カメラで撮影'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, onSelected);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Text(
                    'Hada-Log',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF535D67),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month, color: Colors.teal),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('2026年9月3日', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              const Text('今日の肌調子', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // 気分
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Text('😫', style: TextStyle(fontSize: 32)),
                  Text('🙁', style: TextStyle(fontSize: 32)),
                  Text('😐', style: TextStyle(fontSize: 36)),
                  Text('🙂', style: TextStyle(fontSize: 32)),
                  Text('😊', style: TextStyle(fontSize: 32)),
                ],
              ),
              const SizedBox(height: 20),

              const Text('気になる症状', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // 症状
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  Chip(label: Text('✓ 乾燥'), backgroundColor: Color(0xFFD3E3F0)),
                  Chip(label: Text('赤み')),
                  Chip(label: Text('ニキビ')),
                  Chip(label: Text('かゆみ')),
                  Chip(label: Text('べたつき')),
                ],
              ),
              const SizedBox(height: 20),

              const Text('食事ログ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // 食事ログ（テキスト枠 + カメラ追加枠）
              _buildMealSection('朝食', 'トースト、目玉焼き、コーヒー', _breakfastImage, (img) => _breakfastImage = img),
              const SizedBox(height: 12),
              _buildMealSection('昼食', 'パスタ、サイドサラダ', _lunchImage, (img) => _lunchImage = img),
              const SizedBox(height: 12),
              _buildMealSection('夕食', '焼き魚定食、味噌汁', _dinnerImage, (img) => _dinnerImage = img),

              const SizedBox(height: 20),

              const Text('自由メモ・肌写真', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '今日は少し乾燥している気がする。',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),

              // 肌写真専用追加エリア
              GestureDetector(
                onTap: () => _showImagePickerModal((img) => _skinImage = img),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                  ),
                  child: _skinImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_skinImage!.path), fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, color: Colors.teal, size: 32),
                            SizedBox(height: 4),
                            Text('肌の写真をアタッチ', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A88A5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('今日の記録を保存・AI解析', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 食事＋カメラ用横並びレイアウト
  Widget _buildMealSection(String label, String hint, XFile? image, Function(XFile) onSelected) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              color: Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.teal),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(File(image.path), fit: BoxFit.cover),
                  )
                : const Icon(Icons.camera_alt, color: Colors.teal),
          ),
        ),
      ],
    );
  }
}