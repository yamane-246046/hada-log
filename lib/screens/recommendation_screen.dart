import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recommendedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final response = await _supabase
          .from('items')
          .select('id, name, brand, category, description');

      setState(() {
        _recommendedItems = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データ取得エラー: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('おすすめ市販ケア商品'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recommendedItems.isEmpty
              ? const Center(child: Text('おすすめの商品が見つかりませんでした'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _recommendedItems.length,
                  itemBuilder: (context, index) {
                    final item = _recommendedItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['brand'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.teal[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item['category'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['description'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}