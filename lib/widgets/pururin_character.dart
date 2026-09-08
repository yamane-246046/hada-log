import 'dart:math' as math;
import 'package:flutter/material.dart';

// ぷるりんの表情タイプ
enum PururinEmotion { idle, happy, encourage }

class PururinCharacter extends StatefulWidget {
  final PururinEmotion emotion;
  final double size;
  final String? message;

  const PururinCharacter({
    super.key,
    this.emotion = PururinEmotion.idle,
    this.size = 120.0,
    this.message,
  });

  @override
  State<PururinCharacter> createState() => _PururinCharacterState();
}

class _PururinCharacterState extends State<PururinCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    // 上下にふわふわ浮くアニメーション（1.5秒周期）
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 吹き出しメッセージ（メッセージがある場合のみ表示）
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.message!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ぷるりん本体（ふわふわ動く）
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bounceAnimation.value),
              child: CustomPaint(
                size: Size(widget.size, widget.size * 1.1),
                painter: _PururinPainter(emotion: widget.emotion),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PururinPainter extends CustomPainter {
  final PururinEmotion emotion;

  _PururinPainter({required this.emotion});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. 体（水滴シェイプ）のグラデーション描画
    final bodyPath = Path();
    bodyPath.moveTo(width * 0.5, height * 0.05);
    bodyPath.cubicTo(
      width * 0.85, height * 0.35,
      width * 0.95, height * 0.75,
      width * 0.5, height * 0.95,
    );
    bodyPath.cubicTo(
      width * 0.05, height * 0.75,
      width * 0.15, height * 0.35,
      width * 0.5, height * 0.05,
    );
    bodyPath.close();

    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.teal.shade200,
          Colors.teal.shade500,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(bodyPath, bodyPaint);

    // 2. みずみずしい光沢（ハイライト）
    final highlightPath = Path();
    highlightPath.addOval(
      Rect.fromLTWH(width * 0.25, height * 0.2, width * 0.18, height * 0.25),
    );
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..style = PaintingStyle.fill;
    canvas.drawPath(highlightPath, highlightPaint);

    // 3. ピンクのほっぺ（チーク）
    final cheekPaint = Paint()
      ..color = Colors.pinkAccent.withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.28, height * 0.62), width * 0.08, cheekPaint);
    canvas.drawCircle(Offset(width * 0.72, height * 0.62), width * 0.08, cheekPaint);

    // 4. 目と口（表情に応じた描画）
    final eyePaint = Paint()
      ..color = const Color(0xFF1E3A3A)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF1E3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    if (emotion == PururinEmotion.happy) {
      // 笑顔の目 (^ ^)
      final leftEye = Path()
        ..addArc(
          Rect.fromLTWH(width * 0.28, height * 0.48, width * 0.12, height * 0.12),
          math.pi,
          math.pi,
        );
      final rightEye = Path()
        ..addArc(
          Rect.fromLTWH(width * 0.60, height * 0.48, width * 0.12, height * 0.12),
          math.pi,
          math.pi,
        );
      canvas.drawPath(leftEye, linePaint);
      canvas.drawPath(rightEye, linePaint);

      // 開いた口
      final mouthPath = Path()
        ..moveTo(width * 0.42, height * 0.64)
        ..quadraticBezierTo(width * 0.5, height * 0.78, width * 0.58, height * 0.64)
        ..close();
      canvas.drawPath(mouthPath, eyePaint);

    } else if (emotion == PururinEmotion.encourage) {
      // 寄り添い目
      canvas.drawCircle(Offset(width * 0.33, height * 0.52), width * 0.05, eyePaint);
      canvas.drawCircle(Offset(width * 0.67, height * 0.52), width * 0.05, eyePaint);

      // 波型の口
      final mouthPath = Path()
        ..moveTo(width * 0.42, height * 0.66)
        ..quadraticBezierTo(width * 0.46, height * 0.62, width * 0.5, height * 0.66)
        ..quadraticBezierTo(width * 0.54, height * 0.70, width * 0.58, height * 0.66);
      canvas.drawPath(mouthPath, linePaint);

    } else {
      // 通常の目
      canvas.drawCircle(Offset(width * 0.33, height * 0.52), width * 0.05, eyePaint);
      canvas.drawCircle(Offset(width * 0.67, height * 0.52), width * 0.05, eyePaint);
      // 目の中の輝き
      canvas.drawCircle(
        Offset(width * 0.31, height * 0.50),
        width * 0.018,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(width * 0.65, height * 0.50),
        width * 0.018,
        Paint()..color = Colors.white,
      );

      // にっこり口
      final mouthPath = Path()
        ..moveTo(width * 0.43, height * 0.63)
        ..quadraticBezierTo(width * 0.5, height * 0.72, width * 0.57, height * 0.63);
      canvas.drawPath(mouthPath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PururinPainter oldDelegate) =>
      oldDelegate.emotion != emotion;
}