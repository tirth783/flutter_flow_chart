import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/src/elements/flow_element.dart';
import 'package:flutter_flow_chart/src/objects/element_text_widget.dart';
import 'package:flutter_flow_chart/src/ui/profile_icon_helper.dart';

/// A kind of element
class ImageWidget extends StatefulWidget {
  /// Requires element.data to be an ImageProvider.
  ImageWidget({required this.element, super.key})
      : assert(
          element.data is ImageProvider ||
              (element.serializedData?.isNotEmpty ?? false),
          'Missing image ("data" parameter should be an ImageProvider)',
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
  ui.Image? _cachedImage;
  String? _error;
  ImageProvider? _resizedProvider;

  void _prepareResizedProvider(double diameter) {
    // Memoize resized provider to avoid recreating and causing flicker
    _resizedProvider = ResizeImage(
      widget.imageProvider,
      width: (diameter * 2).toInt(),
      height: (diameter * 2).toInt(),
    );
  }

  @override
  void didUpdateWidget(covariant ImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProvider != widget.imageProvider ||
        oldWidget.element.size != widget.element.size) {
      _resizedProvider = null; // recompute on change
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
                  child: ClipOval(
                    child: Builder(
                      builder: (context) {
                        final bool isDefaultAsset =
                            widget.imageProvider is AssetImage &&
                                (widget.imageProvider as AssetImage)
                                    .assetName
                                    .contains('ic_profile_tree');
                        final bool noSerializedData =
                            (widget.element.serializedData == null) ||
                                (widget.element.serializedData is String &&
                                    (widget.element.serializedData as String)
                                        .isEmpty);
                        if (isDefaultAsset || noSerializedData) {
                          // Render crisp vector/icon fallback instead of blurry raster asset
                          return Container(
                            width: diameter,
                            height: diameter,
                            decoration: BoxDecoration(
                              color: ProfileIconHelper.getGenderColor(
                                widget.element.gender,
                                opacity: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: ProfileIconHelper.getProfileIcon(
                                age: widget.element.age,
                                gender: widget.element.gender,
                                size: diameter * 0.55,
                                color: ProfileIconHelper.getGenderColor(
                                  widget.element.gender,
                                ),
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
                            return Container(
                              width: diameter,
                              height: diameter,
                              decoration: BoxDecoration(
                                color: ProfileIconHelper.getGenderColor(
                                  widget.element.gender,
                                  opacity: 0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: ProfileIconHelper.getProfileIcon(
                                  age: widget.element.age,
                                  gender: widget.element.gender,
                                  size: diameter * 0.55,
                                  color: ProfileIconHelper.getGenderColor(
                                    widget.element.gender,
                                  ),
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
