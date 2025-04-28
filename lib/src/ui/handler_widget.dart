import 'package:flutter/material.dart';

/// The arrow tip.
class HandlerWidget extends StatelessWidget {
  ///
  const HandlerWidget({
    required this.width,
    required this.height,
    super.key,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.black,
    this.icon,
    this.isBorder = true,
  });

  ///
  final double width;

  ///
  final double height;

  ///
  final Color backgroundColor;

  ///
  final Color borderColor;

  final bool isBorder;

  ///
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
        border: isBorder
            ? Border.all(
                width: 2,
                color: const Color(0xFFC3C6D5),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FittedBox(child: icon),
      ),
    );
  }
}
