import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/src/elements/flow_element.dart';

/// Common widget for the element text
class ElementTextWidget extends StatelessWidget {
  ///
  const ElementTextWidget({
    super.key,
    required this.text,
    required this.textColor,
    required this.textSize,
    this.fontFamily,
    this.isBold = false,
  });

  ///
  final String text;
  final Color textColor;
  final double textSize;
  final String? fontFamily;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: textSize,
        fontFamily: fontFamily,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}
