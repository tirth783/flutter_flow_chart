import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:flutter_flow_chart/src/objects/element_text_widget.dart';

/// A kind of element
class ImageWidget extends StatefulWidget {
  /// Renders an element image. Works with network, base64, asset, or no image.
  ImageWidget({
    required this.element,
    super.key,
    required this.pressDelete,
  })  : imageProvider = (() {
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
        })(),
        _imageKey = (() {
          // Create a stable key based on the image source to prevent unnecessary rebuilds
          final sd = element.serializedData;
          if (sd is String && sd.isNotEmpty) {
            return sd;
          }
          final data = element.data;
          if (data is String && data.isNotEmpty) {
            return data;
          }
          if (data is ImageProvider) {
            if (data is NetworkImage) {
              return data.url;
            } else if (data is FileImage) {
              return data.file.path;
            } else if (data is AssetImage) {
              return data.assetName;
            }
          }
          return '${element.id}_default';
        })();

  /// The element to display
  final FlowElement element;
  final Function() pressDelete;

  /// The image provider
  final ImageProvider imageProvider;

  /// Stable key for the image source to prevent unnecessary rebuilds
  final String _imageKey;

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> with AutomaticKeepAliveClientMixin {
  ImageProvider? _resizedProvider;
  double? _lastDiameter;
  Widget? _cachedIconWidget;
  bool? _isDefaultIcon;
  ImageProvider? _cachedImageProvider;
  String? _cachedImageKey;
  Widget? _cachedImageWidget;
  double? _cachedImageDiameter;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize cached ImageProvider in initState to prevent recreation
    _cachedImageProvider = widget.imageProvider;
    _cachedImageKey = widget._imageKey;
  }

  ImageProvider _getStableImageProvider() {
    // Cache the ImageProvider to prevent unnecessary recreation
    if (_cachedImageProvider != null && _cachedImageKey == widget._imageKey) {
      return _cachedImageProvider!;
    }

    // Use the widget's imageProvider if it's already set
    _cachedImageProvider = widget.imageProvider;
    _cachedImageKey = widget._imageKey;
    return _cachedImageProvider!;
  }

  void _prepareResizedProvider(double diameter) {
    // Only recreate if diameter changed significantly to avoid flicker
    final stableProvider = _getStableImageProvider();
    if (_resizedProvider == null || _lastDiameter == null || (diameter - _lastDiameter!).abs() > 5) {
      _resizedProvider = ResizeImage(
        stableProvider,
        width: (diameter * 2).toInt(),
        height: (diameter * 2).toInt(),
      );
      _lastDiameter = diameter;
    }
  }

  Widget _buildDefaultIcon(double diameter) {
    // Cache the icon widget to prevent rebuilds
    if (_cachedIconWidget == null || _lastDiameter != diameter) {
      final tintLight = ProfileIconHelper.getGenderColor(
        widget.element.gender,
        opacity: 0.12,
      );
      final ringColor = ProfileIconHelper.getGenderColor(
        widget.element.gender,
        opacity: 0.65,
      );
      final glyphColor = ProfileIconHelper.getGenderColor(
        widget.element.gender,
        opacity: 0.95,
      );
      final isYou = widget.element.subText.toLowerCase().contains('(you)');

      final outerRing = isYou ? (diameter * 0.06).clamp(2.0, 5.0) : 0.0;
      final innerRing = (diameter * 0.035).clamp(1.0, 3.0);
      final contentSize = diameter - (outerRing * 2);

      _cachedIconWidget = Stack(
        alignment: Alignment.center,
        children: [
          if (isYou)
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent, width: outerRing),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.25),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          Container(
            width: contentSize,
            height: contentSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white, tintLight],
                stops: const [0.7, 1.0],
              ),
              border: Border.all(color: ringColor, width: innerRing),
            ),
          ),
          Center(
            child: ProfileIconHelper.getProfileIcon(
              age: widget.element.age,
              gender: widget.element.gender,
              size: contentSize * 0.6,
              color: glyphColor,
            ),
          ),
        ],
      );
      _lastDiameter = diameter;
    }
    return _cachedIconWidget!;
  }

  bool _shouldShowDefaultIcon() {
    if (_isDefaultIcon != null && _cachedImageKey == widget._imageKey) return _isDefaultIcon!;

    final stableProvider = _getStableImageProvider();
    final isDefaultAsset = stableProvider is AssetImage &&
        (stableProvider as AssetImage).assetName.contains(
              'ic_profile_tree',
            );
    final noSerializedData = (widget.element.serializedData == null) || (widget.element.serializedData is String && (widget.element.serializedData as String).isEmpty);

    _isDefaultIcon = isDefaultAsset || noSerializedData;
    return _isDefaultIcon as bool;
  }

  bool _isSameImageProvider(ImageProvider a, ImageProvider b) {
    if (a == b) return true;
    if (a.runtimeType != b.runtimeType) return false;

    // Compare NetworkImage by URL
    if (a is NetworkImage && b is NetworkImage) {
      return a.url == b.url;
    }

    // Compare FileImage by file path
    if (a is FileImage && b is FileImage) {
      return a.file.path == b.file.path;
    }

    // Compare AssetImage by asset name
    if (a is AssetImage && b is AssetImage) {
      return a.assetName == b.assetName;
    }

    // For other types, use reference equality
    return false;
  }

  @override
  void didUpdateWidget(covariant ImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset if image source actually changed (use stable key to prevent unnecessary resets)
    final imageKeyChanged = oldWidget._imageKey != widget._imageKey;

    if (imageKeyChanged) {
      // Image source changed, reset all cached data
      _cachedImageProvider = null;
      _cachedImageKey = null;
      _resizedProvider = null;
      _lastDiameter = null;
      _cachedIconWidget = null;
      _isDefaultIcon = null;
      _cachedImageWidget = null;
      _cachedImageDiameter = null;
      // Initialize new cached provider
      _cachedImageProvider = widget.imageProvider;
      _cachedImageKey = widget._imageKey;
    } else {
      // Image source hasn't changed, keep using cached provider
      // Don't reset anything - preserve all cached data to prevent blinking
      // Only update cached provider if it's null (shouldn't happen, but safety check)
      if (_cachedImageProvider == null) {
        _cachedImageProvider = widget.imageProvider;
        _cachedImageKey = widget._imageKey;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
                    child: _shouldShowDefaultIcon()
                        ? _buildDefaultIcon(diameter)
                        : ClipOval(
                            key: ValueKey('${widget.element.id}_image_${widget._imageKey}'),
                            child: (() {
                              // Use cached Image widget if diameter and image key haven't changed
                              if (_cachedImageWidget != null && _cachedImageDiameter == diameter && _cachedImageKey == widget._imageKey) {
                                return _cachedImageWidget!;
                              }

                              if (_resizedProvider == null || (_lastDiameter != null && (diameter - _lastDiameter!).abs() > 8)) {
                                _prepareResizedProvider(diameter);
                              }

                              final imageWidget = Image(
                                key: ValueKey('${widget.element.id}_img_${widget._imageKey}'),
                                image: _resizedProvider!,
                                width: diameter,
                                height: diameter,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.high,
                                frameBuilder: (
                                  context,
                                  child,
                                  frame,
                                  wasSynchronouslyLoaded,
                                ) {
                                  // Return child immediately to avoid fade and minimize flicker
                                  return child;
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultIcon(diameter);
                                },
                              );

                              // Cache the Image widget
                              _cachedImageWidget = imageWidget;
                              _cachedImageDiameter = diameter;

                              return imageWidget;
                            })(),
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
