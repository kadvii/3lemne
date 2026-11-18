import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MouthDiagramWidget extends StatelessWidget {
  final String diagramType;
  final double size;

  const MouthDiagramWidget({
    Key? key,
    required this.diagramType,
    this.size = 140,
  }) : super(key: key);

  String get _diagramLabelAr {
    switch (diagramType) {
      case 'bilabial_p_b':
        return 'إطباق الشفتين وحبس الهواء';
      case 'labiodental_f_v':
        return 'الأسنان العلوية على الشفة السفلية';
      case 'interdental_th':
        return 'طرف اللسان بين الأسنان';
      case 'velar_ng':
        return 'أقصى اللسان يغلق الحنك الرخو (غنة أنفية)';
      case 'palato_alveolar_sh_ch':
        return 'اللسان قرب سقف الحلق (مجرى احتكاكي ضيق)';
      case 'alveolar_r':
        return 'طرف اللسان مقوّس دون لمس الحلق';
      case 'bilabial_w':
        return 'ضم الشفتين كدائرة صغيرة للأمام';
      case 'vowel_front_high_i':
        return 'لسان مرتفع للأعلى وشفتان مبتسمتان';
      case 'vowel_back_high_u':
        return 'أقصى اللسان مرتفع وشفتان مستديرتان';
      case 'vowel_front_mid_ae_e':
        return 'الفك مفتوح واللسان منخفض';
      case 'vowel_central_schwa':
        return 'وضع محايد ومسترخٍ تماماً';
      case 'vowel_back_open_o':
        return 'فك منخفض وأقصى اللسان مسحوب للخلف';
      case 'diphthong_glide':
        return 'انزلاق سلس بين حركتين متتاليتين';
      case 'silent_cross':
        return 'حرف صامت تماماً (لا يُنطق)';
      case 'stress_high':
        return 'نبرة صوتية عالية وأطول في المقطع المشدد';
      default:
        return 'انسياب مستمر للهواء دون انقطاع';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: size,
            width: size * 1.5,
            child: CustomPaint(
              painter: _MouthAnatomyPainter(diagramType: diagramType),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Text(
              _diagramLabelAr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF90CAF9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MouthAnatomyPainter extends CustomPainter {
  final String diagramType;

  _MouthAnatomyPainter({required this.diagramType});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Palette
    final palatePaint = Paint()
      ..color = const Color(0xFF546E7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final teethPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final lipsPaint = Paint()
      ..color = const Color(0xFFE57373)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;

    final tonguePaint = Paint()
      ..color = const Color(0xFFEF5350).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final airPaint = Paint()
      ..color = const Color(0xFF64B5F6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    // 1. Draw Hard & Soft Palate (Roof of mouth from left (lips) to right (throat))
    final palatePath = Path()
      ..moveTo(w * 0.28, h * 0.28)
      ..quadraticBezierTo(w * 0.45, h * 0.18, w * 0.72, h * 0.26)
      ..quadraticBezierTo(w * 0.82, h * 0.32, w * 0.85, h * 0.52);
    canvas.drawPath(palatePath, palatePaint);

    // 2. Upper Teeth
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, h * 0.27, w * 0.06, h * 0.14),
        const Radius.circular(3),
      ),
      teethPaint,
    );

    // 3. Lower Teeth
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.25, h * 0.58, w * 0.055, h * 0.13),
        const Radius.circular(3),
      ),
      teethPaint,
    );

    // 4. Upper Lip
    final upperLipPath = Path()
      ..moveTo(w * 0.24, h * 0.24)
      ..quadraticBezierTo(w * 0.14, h * 0.26, w * 0.12, h * 0.35);
    canvas.drawPath(upperLipPath, lipsPaint);

    // 5. Lower Lip - position based on sound
    final lowerLipPath = Path();
    if (diagramType == 'labiodental_f_v') {
      // Lower lip tucked under upper teeth
      lowerLipPath
        ..moveTo(w * 0.23, h * 0.40)
        ..quadraticBezierTo(w * 0.15, h * 0.48, w * 0.16, h * 0.65);
    } else if (diagramType == 'bilabial_p_b') {
      // Lips pressed tightly together
      lowerLipPath
        ..moveTo(w * 0.13, h * 0.35)
        ..quadraticBezierTo(w * 0.13, h * 0.48, w * 0.17, h * 0.65);
    } else if (diagramType == 'bilabial_w' || diagramType == 'vowel_back_high_u') {
      // Lips rounded forward
      lowerLipPath
        ..moveTo(w * 0.08, h * 0.40)
        ..quadraticBezierTo(w * 0.10, h * 0.52, w * 0.18, h * 0.66);
    } else {
      // Normal open lips
      lowerLipPath
        ..moveTo(w * 0.16, h * 0.45)
        ..quadraticBezierTo(w * 0.14, h * 0.56, w * 0.18, h * 0.66);
    }
    canvas.drawPath(lowerLipPath, lipsPaint);

    // 6. Tongue contour depending on diagramType
    final tonguePath = Path();
    tonguePath.moveTo(w * 0.82, h * 0.78); // Tongue root at bottom right

    if (diagramType == 'interdental_th') {
      // Tongue tip protruding through teeth
      tonguePath
        ..quadraticBezierTo(w * 0.58, h * 0.68, w * 0.38, h * 0.55)
        ..lineTo(w * 0.17, h * 0.43) // Tip sticks out between teeth
        ..quadraticBezierTo(w * 0.28, h * 0.56, w * 0.40, h * 0.72)
        ..lineTo(w * 0.68, h * 0.85);
    } else if (diagramType == 'velar_ng' || diagramType == 'vowel_back_high_u') {
      // Tongue back raised high to soft palate
      tonguePath
        ..quadraticBezierTo(w * 0.72, h * 0.35, w * 0.66, h * 0.33)
        ..quadraticBezierTo(w * 0.45, h * 0.55, w * 0.32, h * 0.62)
        ..lineTo(w * 0.30, h * 0.70)
        ..lineTo(w * 0.68, h * 0.85);
    } else if (diagramType == 'alveolar_r') {
      // Retroflex / curled back tongue tip
      tonguePath
        ..quadraticBezierTo(w * 0.60, h * 0.62, w * 0.45, h * 0.50)
        ..quadraticBezierTo(w * 0.35, h * 0.40, w * 0.40, h * 0.34) // curled up/back
        ..quadraticBezierTo(w * 0.32, h * 0.48, w * 0.32, h * 0.68)
        ..lineTo(w * 0.68, h * 0.85);
    } else if (diagramType == 'vowel_front_high_i' || diagramType == 'palato_alveolar_sh_ch') {
      // Tongue blade high front
      tonguePath
        ..quadraticBezierTo(w * 0.65, h * 0.60, w * 0.42, h * 0.32)
        ..quadraticBezierTo(w * 0.32, h * 0.36, w * 0.28, h * 0.55)
        ..lineTo(w * 0.28, h * 0.68)
        ..lineTo(w * 0.68, h * 0.85);
    } else if (diagramType == 'vowel_front_mid_ae_e') {
      // Low front flat tongue, wide jaw
      tonguePath
        ..quadraticBezierTo(w * 0.62, h * 0.68, w * 0.45, h * 0.64)
        ..quadraticBezierTo(w * 0.35, h * 0.65, w * 0.26, h * 0.68)
        ..lineTo(w * 0.26, h * 0.78)
        ..lineTo(w * 0.68, h * 0.88);
    } else {
      // Neutral resting tongue (schwa / p / b / default)
      tonguePath
        ..quadraticBezierTo(w * 0.60, h * 0.62, w * 0.45, h * 0.56)
        ..quadraticBezierTo(w * 0.35, h * 0.58, w * 0.28, h * 0.62)
        ..lineTo(w * 0.28, h * 0.74)
        ..lineTo(w * 0.68, h * 0.85);
    }
    tonguePath.close();
    canvas.drawPath(tonguePath, tonguePaint);

    // 7. Dynamic Articulation Overlays (Burst, Flow, Silent, Stress)
    if (diagramType == 'bilabial_p_b') {
      // Burst rays at lips
      final burstPaint = Paint()
        ..color = const Color(0xFFFFB74D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      for (double angle = -0.6; angle <= 0.6; angle += 0.4) {
        final cx = w * 0.10;
        final cy = h * 0.38;
        final dx = cx - 14 * math.cos(angle);
        final dy = cy + 14 * math.sin(angle);
        canvas.drawLine(Offset(cx, cy), Offset(dx, dy), burstPaint);
      }
    } else if (diagramType == 'velar_ng') {
      // Nasal flow arrow going up into nasal cavity
      final nasalPaint = Paint()
        ..color = const Color(0xFF4FC3F7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      final nasalPath = Path()
        ..moveTo(w * 0.70, h * 0.45)
        ..quadraticBezierTo(w * 0.65, h * 0.15, w * 0.35, h * 0.12)
        ..lineTo(w * 0.16, h * 0.15);
      canvas.drawPath(nasalPath, nasalPaint);
    } else if (diagramType == 'silent_cross') {
      // Big smooth red X mark
      final xPaint = Paint()
        ..color = const Color(0xFFEF5350)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4;
      canvas.drawLine(Offset(w * 0.12, h * 0.25), Offset(w * 0.32, h * 0.60), xPaint);
      canvas.drawLine(Offset(w * 0.32, h * 0.25), Offset(w * 0.12, h * 0.60), xPaint);
    } else if (diagramType == 'stress_high') {
      // Syllable pitch wave
      final wavePaint = Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      final wavePath = Path()
        ..moveTo(w * 0.12, h * 0.50)
        ..lineTo(w * 0.30, h * 0.50)
        ..lineTo(w * 0.45, h * 0.22) // Peak
        ..lineTo(w * 0.60, h * 0.22)
        ..lineTo(w * 0.75, h * 0.50);
      canvas.drawPath(wavePath, wavePaint);
    } else {
      // Smooth airflow stream
      final streamPath = Path()
        ..moveTo(w * 0.60, h * 0.50)
        ..quadraticBezierTo(w * 0.40, h * 0.45, w * 0.10, h * 0.45);
      canvas.drawPath(streamPath, airPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MouthAnatomyPainter oldDelegate) {
    return oldDelegate.diagramType != diagramType;
  }
}

