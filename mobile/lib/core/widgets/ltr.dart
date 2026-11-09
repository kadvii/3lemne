import 'package:flutter/widgets.dart';

/// ويدجت لإجبار عرض المحتوى الإنجليزي من اليسار لليمين (LTR)
/// حتى داخل التطبيقات ذات الاتجاه العام العربي (RTL)
class Ltr extends StatelessWidget {
  final Widget child;

  const Ltr({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
  }
}

