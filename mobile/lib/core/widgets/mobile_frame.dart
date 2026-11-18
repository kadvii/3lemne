import 'package:flutter/material.dart';

class MobileFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MobileFrame({
    Key? key,
    required this.child,
    this.maxWidth = 480,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF090D16),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

