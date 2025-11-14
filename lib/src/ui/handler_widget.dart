import 'package:flutter/material.dart';

/// The arrow tip.
class HandlerWidget extends StatelessWidget {
  ///
  const HandlerWidget({
    required this.width,
    required this.height,
    super.key,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xffC3C6D5),
    this.icon,
  });

  ///
  final double width;

  ///
  final double height;

  ///
  final Color backgroundColor;

  ///
  final Color borderColor;

  ///
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          width: 2,
          color: const Color(0xFF4BA3FF),
        ),
      ),
      // Only show inner content if an explicit icon is provided; otherwise empty to avoid inner dot when zooming
      child: icon != null
          ? Padding(
              padding: const EdgeInsets.all(3),
              child: FittedBox(child: icon),
            )
          : null,
    );
  }
}
