import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';

/// Common widget for the element text
class ElementTextWidget extends StatefulWidget {
  ///
  const ElementTextWidget({
    required this.element,
    super.key,
  });

  ///
  final FlowElement element;

  @override
  State<ElementTextWidget> createState() => _ElementTextWidgetState();
}

class _ElementTextWidgetState extends State<ElementTextWidget> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller
      ..text = widget.element.text
      ..addListener(() => widget.element.text = _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: widget.element.textColor,
      fontSize: widget.element.textSize,
      fontWeight: widget.element.textIsBold ? FontWeight.bold : FontWeight.normal,
      fontFamily: widget.element.fontFamily,
    );

    final subTextStyle = TextStyle(
      color: widget.element.subTextColor,
      fontSize: widget.element.subTextSize,
      fontFamily: widget.element.fontFamily,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Align(
          child: widget.element.isEditingText
              ? TextFormField(
                  controller: _controller,
                  autofocus: true,
                  onTapOutside: (event) => dismissTextEditor(),
                  onFieldSubmitted: dismissTextEditor,
                  textAlign: TextAlign.center,
                  style: textStyle,
                )
              : Text(
                  widget.element.text,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
        ),
        Text(
          widget.element.subText,
          textAlign: TextAlign.center,
          style: subTextStyle,
        )
      ],
    );
  }

  void dismissTextEditor([String? text]) {
    if (text != null) widget.element.text = text;
    setState(() => widget.element.isEditingText = false);
  }
}
