import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/src/elements/flow_element.dart';
import 'package:flutter_flow_chart/src/objects/element_text_widget.dart';
import 'package:flutter_flow_chart/src/ui/profile_icon_helper.dart';

/// A kind of element
class ImageWidget extends StatefulWidget {
  /// Renders an element image. Works with network, base64, asset, or no image.
  ImageWidget({required this.element, super.key})
    : imageProvider = (() {
        // Prefer serializedData when available
        final sd = element.serializedData;
        if (sd is String && sd.isNotEmpty) {
          if (sd.startsWith('http')) {
            return NetworkImage(sd);
          }
          try {
            return Image.memory(base64Decode(sd)).image;
          } catch (_) {
            // fallthrough to data/provider/default
          }
        }
        // If element.data is a base64/http string, use it
        final data = element.data;
        if (data is String && data.isNotEmpty) {
          if (data.startsWith('http')) {
            return NetworkImage(data);
          }
          try {
            return Image.memory(base64Decode(data)).image;
          } catch (_) {
            // ignore, fallback to provider/default
          }
        }
        // Fallback to provided ImageProvider if present
        if (element.data is ImageProvider) {
          return element.data as ImageProvider;
        }
        // Default placeholder (will be replaced by icon in build)
        return const AssetImage('assets/icons/ic_profile_tree.png');
      })();

  /// The element to display
  final FlowElement element;

  /// The image provider
  final ImageProvider imageProvider;

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  ui.Image? _cachedImage;
  String? _error;
  ImageProvider? _resizedProvider;
  double? _lastDiameter;

  void _prepareResizedProvider(double diameter) {
    // Only recreate if diameter changed significantly to avoid flicker
    if (_resizedProvider == null || 
        _lastDiameter == null || 
        (diameter - _lastDiameter!).abs() > 5) {
      _resizedProvider = ResizeImage(
        widget.imageProvider,
        width: (diameter * 2).toInt(),
        height: (diameter * 2).toInt(),
      );
      _lastDiameter = diameter;
    }
  }

  @override
  void didUpdateWidget(covariant ImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset if image provider actually changed (not on every rebuild)
    if (oldWidget.imageProvider.runtimeType != widget.imageProvider.runtimeType ||
        oldWidget.imageProvider != widget.imageProvider) {
      _resizedProvider = null;
      _lastDiameter = null;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.element.size.width;
    final h = widget.element.size.height;

    final double diameter = math.min(w * 0.8, h * 0.6);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          // Background + border
          Container(
            decoration: BoxDecoration(
              color: widget.element.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.element.borderColor,
                width: widget.element.borderThickness,
              ),
            ),
          ),

          // Image + text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular image
              Expanded(
                flex: 3,
                child: Center(
                  child: RepaintBoundary(
                    child: ClipOval(
                      child: Builder(
                      builder: (context) {
                        final bool isDefaultAsset =
                            widget.imageProvider is AssetImage &&
                            (widget.imageProvider as AssetImage).assetName
                                .contains('ic_profile_tree');
                        final bool noSerializedData =
                            (widget.element.serializedData == null) ||
                            (widget.element.serializedData is String &&
                                (widget.element.serializedData as String)
                                    .isEmpty);
                        if (isDefaultAsset || noSerializedData) {
                          // Render clean single icon for all profiles
                          return Container(
                            width: diameter,
                            height: diameter,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person,
                                size: diameter * 0.6,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }

                        if (_resizedProvider == null) {
                          _prepareResizedProvider(diameter);
                        }
                        return Image(
                          image: _resizedProvider!,
                          width: diameter,
                          height: diameter,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.high,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                                return child; // avoid fade to minimize flicker
                              },
                          errorBuilder: (context, error, stackTrace) {
                            // Clean fallback on error
                            return Container(
                              width: diameter,
                              height: diameter,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  size: diameter * 0.6,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      ),
                    ),
                  ),
                ),
              ),

              // Text beneath
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
