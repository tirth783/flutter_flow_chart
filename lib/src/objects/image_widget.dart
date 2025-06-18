import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/src/elements/flow_element.dart';
import 'package:flutter_flow_chart/src/objects/element_text_widget.dart';

/// A kind of element
class ImageWidget extends StatefulWidget {
  /// Requires element.data to be an ImageProvider.
  ImageWidget({
    required this.element,
    super.key,
  })  : assert(
          element.data is ImageProvider || (element.serializedData?.isNotEmpty ?? false),
          'Missing image (\"data\" parameter should be an ImageProvider)',
        ),
        imageProvider = element.serializedData?.isNotEmpty ?? false
            ? (element.serializedData!.startsWith('http')
                ? NetworkImage(element.serializedData!)
                : Image.memory(base64Decode(element.serializedData!)).image)
            : element.data as ImageProvider;

  /// The element to display
  final FlowElement element;

  /// The image provider
  final ImageProvider imageProvider;

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  @override
  Widget build(BuildContext context) {
    final w = widget.element.size.width;
    final h = widget.element.size.height;

    final double diameter = math.min(w * 0.8, h * 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: widget.element.borderColor,
                width: widget.element.borderThickness,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: widget.imageProvider,
                fit: BoxFit.cover,
                width: diameter,
                height: diameter,
              ),
            ),
          ),
        ),
        if (widget.element.text.isNotEmpty)
          ElementTextWidget(
            text: widget.element.text,
            textColor: widget.element.textColor,
            textSize: widget.element.textSize,
            fontFamily: widget.element.fontFamily,
            isBold: widget.element.textIsBold,
          ),
        if (widget.element.subText.isNotEmpty)
          ElementTextWidget(
            text: widget.element.subText,
            textColor: widget.element.subTextColor,
            textSize: widget.element.subTextSize,
            fontFamily: widget.element.fontFamily,
            isBold: widget.element.textIsBold,
          ),
      ],
    );
  }
}
