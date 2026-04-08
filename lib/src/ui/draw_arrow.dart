import 'dart:async'; // Add this import for Timer
import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:flutter_flow_chart/src/ui/segment_handler.dart';
import 'package:flutter_flow_chart/src/utils/stream_builder.dart';

/// Must match [ElementWidget]'s delete handle size — used to compute handler offset.
const double _kDeleteHandleScreenSize = 28.0;

/// Arrow style enumeration
enum ArrowStyle {
  /// A curved arrow which points nicely to each handlers
  curve,

  /// A segmented line where pivot points can be added and curvature between
  /// them can be adjusted with a tension.
  segmented,

  /// A rectangular shaped line.
  rectangular,
}

// // Add this color list at the top of the file
// const List<int> kArrowColors = [
//   4278190080,
//   4294901760,
//   4278255360,
//   4278190335,
//   4294902015,
//   4294944000,
//   4286578816,
//   4281348142,
//   4286611456,
//   4278190208,
//   4278222976,
//   4283193858,
//   4294956800,
//   4290822336,
//   4286578688,
//   4278222848,
//   4294797754,
//   4283215697,
//   4279911631
// ];

/// Arrow style enumeration
// enum ArrowStyle {
//   /// A curved arrow which points nicely to each handlers
//   curve,
//
//   /// A segmented line where pivot points can be added and curvature between
//   /// them can be adjusted with a tension.
//   segmented,
//
//   /// A rectangular shaped line.
//   rectangular,
// }

Timer? webTimer;

/// Arrow parameters used by [DrawArrow] widget
class ArrowParams extends ChangeNotifier {
  ///
  ArrowParams({
    this.thickness = 1.7,
    this.headRadius = 6,
    double tailLength = 25.0,
    this.color = const Color(0xff2D8BBF),
    this.style,
    this.tension = 1.0,
    this.startArrowPosition = Alignment.centerRight,
    this.endArrowPosition = Alignment.centerLeft,
    this.cornerRadius = 16.0,
    this.spouseElementId,
    // this.clickableWidth = 15.0, // Added clickable width parameter
  }) : _tailLength = tailLength;

  /// Optional ID of the partner element to calculate mid-point for T-junctions
  final String? spouseElementId;

  ///
  factory ArrowParams.fromMap(Map<String, dynamic> map) {
    return ArrowParams(
      thickness: (map['thickness'] as num?)?.toDouble() ?? 1.2,
      headRadius: (map['headRadius'] as num?)?.toDouble() ?? 6.0,
      tailLength: (map['tailLength'] as num?)?.toDouble() ?? 35.0,
      color: Color(map['color'] as int),
      style: ArrowStyle.values[map['style'] as int? ?? 0],
      tension: (map['tension'] as num?)?.toDouble() ?? 1.0,
      startArrowPosition: Alignment(
        (map['startArrowPositionX'] as num?)?.toDouble() ?? 0.0,
        (map['startArrowPositionY'] as num?)?.toDouble() ?? 0.0,
      ),
      endArrowPosition: Alignment(
        (map['endArrowPositionX'] as num?)?.toDouble() ?? 0.0,
        (map['endArrowPositionY'] as num?)?.toDouble() ?? 0.0,
      ),
      cornerRadius: (map['cornerRadius'] as num?)?.toDouble() ?? 16.0,
      spouseElementId: map['spouseElementId']?.toString(),
      // clickableWidth: map['clickableWidth'] as double? ?? 15.0,
    );
  }

  ///
  Map<String, dynamic> toMap() {
    return {
      'thickness': thickness,
      'headRadius': headRadius,
      'tailLength': _tailLength,
      'color': color.value,
      'style': style?.index ?? 0,
      'tension': tension,
      'startArrowPositionX': startArrowPosition.x,
      'startArrowPositionY': startArrowPosition.y,
      'endArrowPositionX': endArrowPosition.x,
      'endArrowPositionY': endArrowPosition.y,
      'cornerRadius': cornerRadius,
      'spouseElementId': spouseElementId,
      // 'clickableWidth': clickableWidth,
    };
  }

  ///
  ArrowParams copyWith({
    double? thickness,
    double? headRadius,
    double? tailLength,
    Color? color,
    ArrowStyle? style,
    double? tension,
    Alignment? startArrowPosition,
    Alignment? endArrowPosition,
    double? cornerRadius,
    String? spouseElementId,
  }) {
    return ArrowParams(
      thickness: thickness ?? this.thickness,
      headRadius: headRadius ?? this.headRadius,
      tailLength: tailLength ?? _tailLength,
      color: color ?? this.color,
      style: style ?? this.style,
      tension: tension ?? this.tension,
      startArrowPosition: startArrowPosition ?? this.startArrowPosition,
      endArrowPosition: endArrowPosition ?? this.endArrowPosition,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      spouseElementId: spouseElementId ?? this.spouseElementId,
    );
  }

  ///
  factory ArrowParams.fromJson(String source) => ArrowParams.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Arrow thickness.
  double thickness;

  /// The radius of arrow tip.
  double headRadius;

  /// Arrow color.
  final Color color;

  /// The start position alignment.
  final Alignment startArrowPosition;

  /// The end position alignment.
  final Alignment endArrowPosition;

  /// The tail length of the arrow.
  double _tailLength;

  /// The style of the arrow.
  ArrowStyle? style;

  /// The curve tension for pivot points when using [ArrowStyle.segmented].
  /// 0 means no curve on segments.
  double tension;

  /// Corner radius for rectangular line routing.
  /// Set to 0 for sharp T-junction corners. Defaults to 16.0.
  double cornerRadius;

  /// The clickable width of the line (invisible hit area)
  // double clickableWidth;

  ///
  String toJson() => json.encode(toMap());

  ///
  void setScale(double currentZoom, double factor) {
    thickness = thickness / currentZoom * factor;
    // Keep arrow head size constant regardless of zoom/connecting
    headRadius = headRadius;
    _tailLength = _tailLength / currentZoom * factor;
    // clickableWidth = clickableWidth / currentZoom * factor;
    notifyListeners();
  }

  ///
  double get tailLength => _tailLength;
}

/// Notifier to update arrows position, starting/ending points and params
class DrawingArrow extends ChangeNotifier {
  DrawingArrow._();

  /// Singleton instance of this.
  static final instance = DrawingArrow._();

  /// Arrow parameters.
  ArrowParams params = ArrowParams();

  /// Sets the parameters.
  void setParams(ArrowParams params) {
    this.params = params;
    notifyListeners();
  }

  /// Starting arrow offset.
  Offset from = Offset.zero;

  ///
  void setFrom(Offset from) {
    this.from = from;
    notifyListeners();
  }

  /// Ending arrow offset.
  Offset to = Offset.zero;

  ///
  void setTo(Offset to) {
    this.to = to;
    notifyListeners();
  }

  ///
  bool isZero() {
    return from == Offset.zero && to == Offset.zero;
  }

  ///
  void reset() {
    params = ArrowParams();
    from = Offset.zero;
    to = Offset.zero;
    notifyListeners();
  }
}

/// Draw arrow from [srcElement] to [destElement]
/// using [arrowParams] parameters
class DrawArrow extends StatefulWidget {
  ///
  DrawArrow({
    required this.srcElement,
    required this.destElement,
    required List<Pivot> pivots,
    this.dashboard,
    this.spouseElement, // Direct injection of spouse element
    super.key,
    ArrowParams? arrowParams,
    this.clickedColor = Colors.red,
    this.clickDuration = const Duration(seconds: 3),
  })  : arrowParams = arrowParams ?? ArrowParams(),
        pivots = PivotsNotifier(pivots);

  final Dashboard? dashboard;
  final FlowElement? spouseElement;

  ///
  final ArrowParams arrowParams;

  ///
  final FlowElement srcElement;

  ///
  final FlowElement destElement;

  ///
  final PivotsNotifier pivots;

  ///
  // final Function(FlowElement, FlowElement, Offset) connectionLinePressed;

  ///
  final Color clickedColor;

  ///
  final Duration clickDuration;

  // static ArrowParams _randomArrowParams() {
  //   final random = Random();
  //   final colorInt = kArrowColors[random.nextInt(kArrowColors.length)];
  //   return ArrowParams(color: Color(colorInt));
  // }

  @override
  State<DrawArrow> createState() => _DrawArrowState();
}

class _DrawArrowState extends State<DrawArrow> {
  bool _isClicked = false;
  Timer? _colorTimer;

  FlowElement? _spouseElement;

  @override
  void initState() {
    super.initState();
    widget.srcElement.addListener(_elementChanged);
    widget.destElement.addListener(_elementChanged);
    widget.pivots.addListener(_elementChanged);
    widget.spouseElement?.addListener(_elementChanged);
  }

  @override
  void didUpdateWidget(DrawArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spouseElement != oldWidget.spouseElement) {
      oldWidget.spouseElement?.removeListener(_elementChanged);
      widget.spouseElement?.addListener(_elementChanged);
    }
  }

  @override
  void dispose() {
    _colorTimer?.cancel();
    webTimer?.cancel();
    widget.srcElement.removeListener(_elementChanged);
    widget.destElement.removeListener(_elementChanged);
    widget.pivots.removeListener(_elementChanged);
    widget.spouseElement?.removeListener(_elementChanged);
    super.dispose();
  }

  void _elementChanged() {
    if (mounted) setState(() {});
  }

  // void _onLineClicked(Offset position) {
  //   if (StreamBuilderUtils.isDragging.value) {
  //     // Ignore clicks while drawing connections
  //     print('Click ignored - in connection drawing mode');
  //     return;
  //   }
  //
  //   // Cancel any existing timer
  //   _colorTimer?.cancel();
  //   webTimer?.cancel();
  //
  //   // Set clicked state and change color
  //
  //   if(kIsWeb){
  //     webTimer = Timer(Duration(seconds: 2), () {
  //       setState(() {
  //         _isClicked = true;
  //       });
  //
  //       // Call the original callback
  //       print('Click on Line - Source: ${widget.srcElement.id}, Destination: ${widget.destElement.id}');
  //       widget.connectionLinePressed(widget.srcElement, widget.destElement, position);
  //
  //       // Start timer to revert color after specified duration
  //       _colorTimer = Timer(Duration(seconds: 3), () {
  //         webTimer?.cancel();
  //         if (mounted) {
  //           setState(() {
  //             _isClicked = false;
  //           });
  //         }
  //       });
  //     });
  //   }else {
  //     setState(() {
  //       _isClicked = true;
  //     });
  //
  //     // Call the original callback
  //     print('Click on Line - Source: ${widget.srcElement.id}, Destination: ${widget.destElement.id}');
  //     widget.connectionLinePressed(widget.srcElement, widget.destElement, position);
  //
  //     // Start timer to revert color after specified duration
  //     _colorTimer = Timer(widget.clickDuration, () {
  //       if (mounted) {
  //         setState(() {
  //           _isClicked = false;
  //         });
  //       }
  //     });
  //   }
  // }

  // void _onLineClicked(Offset position) {
  //   if (StreamBuilderUtils.isDragging.value) {
  //     print('Click ignored - in connection drawing mode');
  //     return;
  //   }
  //
  //   // Cancel any existing timers
  //   _colorTimer?.cancel();
  //   webTimer?.cancel();
  //
  //   void triggerClick(Duration revertDuration) {
  //     setState(() => _isClicked = true);
  //
  //     print('Click on Line - Source: ${widget.srcElement.id}, Destination: ${widget.destElement.id}');
  //     widget.connectionLinePressed(widget.srcElement, widget.destElement, position);
  //
  //     _colorTimer = Timer(revertDuration, () {
  //       if (mounted) setState(() => _isClicked = false);
  //     });
  //   }
  //
  //   if (kIsWeb) {
  //     webTimer = Timer(const Duration(seconds: 2), () {
  //       triggerClick(const Duration(seconds: 3));
  //     });
  //   } else {
  //     triggerClick(widget.clickDuration);
  //   }
  // }

  /// Computes the extra inset applied by [ElementWidget] when delete/resize handles exist.
  /// Arrow endpoints must match the handler positions, which are offset by this inset.
  static double _extraInsetFor(FlowElement element) {
    final base = element.handlerSize;
    final resize = element.isResizable ? base * 1.5 : base;
    final delete = element.isDeletable ? _kDeleteHandleScreenSize : 0.0;
    final reserved = math.max(base, math.max(resize, delete));
    return (reserved - base) / 2;
  }

  @override
  Widget build(BuildContext context) {
    var from = Offset.zero;
    var to = Offset.zero;
    var direction = 'Empty';

    final srcInset = _extraInsetFor(widget.srcElement);
    final destInset = _extraInsetFor(widget.destElement);

    if (widget.spouseElement != null) {
      // DYNAMIC T-JUNCTION: Use visual center of parents bypassing insets for perfect alignment
      final double s1x = widget.srcElement.position.dx + _extraInsetFor(widget.srcElement) + widget.srcElement.handlerSize / 2.0;
      final double s2x = widget.spouseElement!.position.dx + _extraInsetFor(widget.spouseElement!) + widget.spouseElement!.handlerSize / 2.0;

      final double midX = (s1x + widget.srcElement.size.width / 2.0 + s2x + widget.spouseElement!.size.width / 2.0) / 2.0;

      // Calculate midY based on the y-alignment of the startArrowPosition (0.0=center, 1.0=bottom)
      final double startYAlign = (widget.arrowParams.startArrowPosition.y + 1) / 2.0;
      final double s1y = widget.srcElement.position.dy + _extraInsetFor(widget.srcElement) + widget.srcElement.handlerSize / 2.0 + (widget.srcElement.size.height * startYAlign);
      final double s2y = widget.spouseElement!.position.dy + _extraInsetFor(widget.spouseElement!) + widget.spouseElement!.handlerSize / 2.0 + (widget.spouseElement!.size.height * startYAlign);
      final double midY = (s1y + s2y) / 2.0;

      from = Offset(midX, midY);
    } else {
      from = Offset(
        widget.srcElement.position.dx +
            srcInset +
            widget.srcElement.handlerSize / 2.0 +
            (widget.srcElement.size.width * ((widget.arrowParams.startArrowPosition.x + 1) / 2)),
        widget.srcElement.position.dy +
            srcInset +
            widget.srcElement.handlerSize / 2.0 +
            (widget.srcElement.size.height * ((widget.arrowParams.startArrowPosition.y + 1) / 2)),
      );
    }
    to = Offset(
      widget.destElement.position.dx +
          destInset +
          widget.destElement.handlerSize / 2.0 +
          (widget.destElement.size.width * ((widget.arrowParams.endArrowPosition.x + 1) / 2)),
      widget.destElement.position.dy +
          destInset +
          widget.destElement.handlerSize / 2.0 +
          (widget.destElement.size.height * ((widget.arrowParams.endArrowPosition.y + 1) / 2)),
    );

    direction = getOffsetDirection(to, widget.destElement.position, widget.destElement.size);

    final currentArrowParams =
    _isClicked ? widget.arrowParams.copyWith(color: widget.clickedColor) : widget.arrowParams;
    //final currentArrowParams = _isClicked ? widget.arrowParams.copyWith(thickness: 3.5) : widget.arrowParams;

    final arrowPainter = ArrowPainter(
      params: currentArrowParams,
      from: from,
      to: to,
      pivots: widget.pivots.value,
      direction: direction,
      onLinePressed: (position) {
        print('ClickOnLine: currentArrowParams');
        // _onLineClicked(position);
      },
    );

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTapDown: (TapDownDetails details) {
        if (StreamBuilderUtils.isDragging.value) {
          print('Tap ignored - in connection drawing mode');
          return;
        }

        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.globalPosition);

        if (arrowPainter.hitTest(localPosition) ?? false) {
          print('ClickOnLine: localPosition');
          // _onLineClicked(localPosition);
        }
      },
      child: RepaintBoundary(
        child: CustomPaint(
          painter: arrowPainter,
          size: Size.infinite,
          child: Container(),
        ),
      ),
    );
  }

  String getOffsetDirection(Offset to, Offset boxPosition, Size boxSize) {
    final double centerX = boxPosition.dx + boxSize.width / 2;
    final double centerY = boxPosition.dy + boxSize.height / 2;

    final double deltaX = to.dx - centerX;
    final double deltaY = to.dy - centerY;

    if (deltaX.abs() > deltaY.abs()) {
      return deltaX > 0 ? "Right" : "Left"; // More horizontal movement
    } else {
      return deltaY > 0 ? "Bottom" : "Top"; // More vertical movement
    }
  }
}

/// Paint the arrow connection taking in count the
/// [ArrowParams.startArrowPosition] and
/// [ArrowParams.endArrowPosition] alignment.
class ArrowPainter extends CustomPainter {
  ///
  ArrowPainter({
    required this.params,
    required this.from,
    required this.to,
    required this.direction,
    List<Pivot>? pivots,
    this.onLinePressed,
  }) : pivots = pivots ?? [];

  ///
  final ArrowParams params;

  ///
  final Offset from;

  ///
  final Offset to;

  ///
  final Path path = Path();

  ///
  final List<List<Offset>> lines = [];

  ///
  final List<Pivot> pivots;

  ///
  final Function(Offset)? onLinePressed;

  final String direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = params.thickness
      ..color = params.color
      ..style = PaintingStyle.stroke;

    if (params.style == ArrowStyle.segmented) {
      drawLine();
    } else if (params.style == ArrowStyle.rectangular) {
      drawRectangularLine(canvas, paint);
    } else {
      // Default to curve for new connections (handles null/default)
      drawCurve(canvas, paint);
    }

    // Do not draw any arrowheads for Family Tree connections
    // Simply draw the final computed path.
    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  /// Draw a bottom-facing arrowhead
  void drawBottomArrowHead(Canvas canvas, Paint paint, Offset tip) {
    final arrowHeadSize = params.headRadius * 1.2;
    final arrowTip = tip;
    final arrowLeft = Offset(tip.dx - arrowHeadSize, tip.dy - arrowHeadSize);
    final arrowRight = Offset(tip.dx + arrowHeadSize, tip.dy - arrowHeadSize);

    final arrowHeadPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowLeft.dx, arrowLeft.dy)
      ..lineTo(arrowRight.dx, arrowRight.dy)
      ..close();

    paint.style = PaintingStyle.fill;
    canvas.drawPath(arrowHeadPath, paint);
  }

  void drawTopArrowHead(Canvas canvas, Paint paint, Offset tip) {
    final arrowHeadSize = params.headRadius * 1.2;
    final arrowTip = tip;
    final arrowLeft = Offset(tip.dx - arrowHeadSize, tip.dy + arrowHeadSize);
    final arrowRight = Offset(tip.dx + arrowHeadSize, tip.dy + arrowHeadSize);

    final arrowHeadPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowLeft.dx, arrowLeft.dy)
      ..lineTo(arrowRight.dx, arrowRight.dy)
      ..close();

    paint.style = PaintingStyle.fill;
    canvas.drawPath(arrowHeadPath, paint);
  }

  void drawLeftArrowHead(Canvas canvas, Paint paint, Offset tip) {
    final arrowHeadSize = params.headRadius * 1.2;
    final arrowTip = tip;
    final arrowTop = Offset(tip.dx + arrowHeadSize, tip.dy - arrowHeadSize);
    final arrowBottom = Offset(tip.dx + arrowHeadSize, tip.dy + arrowHeadSize);

    final arrowHeadPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowTop.dx, arrowTop.dy)
      ..lineTo(arrowBottom.dx, arrowBottom.dy)
      ..close();

    paint.style = PaintingStyle.fill;
    canvas.drawPath(arrowHeadPath, paint);
  }

  void drawRightArrowHead(Canvas canvas, Paint paint, Offset tip) {
    final arrowHeadSize = params.headRadius * 1.2;
    final arrowTip = tip;
    final arrowTop = Offset(tip.dx - arrowHeadSize, tip.dy - arrowHeadSize);
    final arrowBottom = Offset(tip.dx - arrowHeadSize, tip.dy + arrowHeadSize);

    final arrowHeadPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(arrowTop.dx, arrowTop.dy)
      ..lineTo(arrowBottom.dx, arrowBottom.dy)
      ..close();

    paint.style = PaintingStyle.fill;
    canvas.drawPath(arrowHeadPath, paint);
  }

  void drawCircleAtEnd(Canvas canvas, Paint paint, Offset tip) {
    final double circleRadius = params.headRadius * 1.2;
    canvas.drawCircle(tip, circleRadius, paint);
  }

  /// Draw a segmented line with a tension between points.
  void drawLine() {
    final points = [from];
    for (final pivot in pivots) {
      points.add(pivot.pivot);
    }
    points.add(to);

    path.moveTo(points.first.dx, points.first.dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = (i > 0) ? points[i - 1] : points[0];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = (i != points.length - 2) ? points[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6 * params.tension;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6 * params.tension;

      final cp2x = p2.dx - (p3.dx - p1.dx) / 6 * params.tension;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6 * params.tension;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }
  }

  /// Draw a rectangular line with rounded corners
  // void drawRectangularLine(Canvas canvas, Paint paint) {
  //   var pivot1 = Offset(from.dx, from.dy);
  //   // First offset away from the source based on start alignment (vertical tail)
  //   if (params.startArrowPosition.y == 1) {
  //     pivot1 = Offset(from.dx, from.dy + params.tailLength);
  //   } else if (params.startArrowPosition.y == -1) {
  //     pivot1 = Offset(from.dx, from.dy - params.tailLength);
  //   } else if (params.startArrowPosition.x != 0) {
  //     // If start side is left/right, create a small horizontal tail instead
  //     final double sign = params.startArrowPosition.x > 0 ? 1.0 : -1.0;
  //     pivot1 = Offset(from.dx + sign * params.tailLength, from.dy);
  //   }
  //
  //   // Decide elbow so the final segment matches the end side (horizontal for L/R, vertical for Top/Bottom)
  //   late final Offset pivot2;
  //   if (params.endArrowPosition.x != 0 && params.endArrowPosition.y == 0) {
  //     // End on left/right → final segment must be horizontal → align Y first
  //     pivot2 = Offset(pivot1.dx, to.dy);
  //   } else {
  //     // End on top/bottom → final segment must be vertical → align X first
  //     pivot2 = Offset(to.dx, pivot1.dy);
  //   }
  //
  //   final double radius = params.cornerRadius;
  //
  //   void addCornerToPath(Offset start, Offset corner, Offset end) {
  //     final dx1 = corner.dx - start.dx;
  //     final dy1 = corner.dy - start.dy;
  //     final len1 = math.sqrt(dx1 * dx1 + dy1 * dy1);
  //
  //     final dx2 = end.dx - corner.dx;
  //     final dy2 = end.dy - corner.dy;
  //     final len2 = math.sqrt(dx2 * dx2 + dy2 * dy2);
  //
  //     if (len1 < 1.0 || len2 < 1.0 || radius <= 0.0) {
  //       path.lineTo(corner.dx, corner.dy);
  //       return;
  //     }
  //
  //     final r = math.min(radius, math.min(len1 / 2, len2 / 2));
  //
  //     final cornerStartX = corner.dx - (dx1 / len1) * r;
  //     final cornerStartY = corner.dy - (dy1 / len1) * r;
  //     path.lineTo(cornerStartX, cornerStartY);
  //
  //     final cornerEndX = corner.dx + (dx2 / len2) * r;
  //     final cornerEndY = corner.dy + (dy2 / len2) * r;
  //
  //     // Compute the cross product to determine clockwise vs counter-clockwise arc
  //     final crossProduct = dx1 * dy2 - dy1 * dx2;
  //     final isClockwise = crossProduct > 0;
  //
  //     // Use arcToPoint which evaluates perfectly in Impeller bounds logic
  //     // unlike quadraticBezierTo which can trigger collinear culling.
  //     path.arcToPoint(
  //       Offset(cornerEndX, cornerEndY),
  //       radius: Radius.circular(r),
  //       clockwise: isClockwise,
  //     );
  //   }
  //
  //   path.moveTo(from.dx, from.dy);
  //   addCornerToPath(from, pivot1, pivot2);
  //   addCornerToPath(pivot1, pivot2, to);
  //   path.lineTo(to.dx, to.dy);
  //
  //   lines.addAll([
  //     [from, pivot2],
  //     [pivot2, to],
  //   ]);
  // }

  /// Draw a rectangular line with rounded corners.
  /// Fixed: handles the degenerate collinear case (straight vertical/horizontal
  /// drop where pivot1 == pivot2) that previously caused Impeller/Skia to
  /// cull the middle segment entirely, producing a visible gap in the line.
  void drawRectangularLine(Canvas canvas, Paint paint) {
    // ── Step 1: compute pivot1 (tail away from source) ──────────────────
    Offset pivot1 = from;
    if (params.startArrowPosition.y == 1) {
      pivot1 = Offset(from.dx, from.dy + params.tailLength);
    } else if (params.startArrowPosition.y == -1) {
      pivot1 = Offset(from.dx, from.dy - params.tailLength);
    } else {
      // If Y is centered (0), determine if this is a side-to-side connection
      // (like a spouse line) or a top-to-bottom connection (like a child trunk).
      if (params.startArrowPosition.x != 0 && params.endArrowPosition.x != 0) {
        // DYNAMIC T-JUNCTION SUPPORT for spouse lines:
        // Always route side-to-side lines with their elbow exactly half-way to destination.
        // This ensures they perfectly align with child trunk lines natively in edit mode!
        pivot1 = Offset((from.dx + to.dx) / 2, from.dy);
      } else if (to.dy > from.dy) {
        // For vertically dropping connections, we want a vertical tail starting from the center midline.
        pivot1 = Offset(from.dx, from.dy + params.tailLength);
      } else {
        // Fallback for sideways single-parent child dragging above parents
        final double sign = params.startArrowPosition.x > 0 ? 1.0 : -1.0;
        pivot1 = Offset(from.dx + sign * params.tailLength, from.dy);
      }
    }

    // ── Step 2: compute pivot2 (the elbow) ──────────────────────────────
    final Offset pivot2;
    if (params.endArrowPosition.x != 0 && params.endArrowPosition.y == 0) {
      pivot2 = Offset(pivot1.dx, to.dy);
    } else {
      pivot2 = Offset(to.dx, pivot1.dy);
    }

    path.moveTo(from.dx, from.dy);

    // ── Step 3: DEGENERATE-CASE GUARD ───────────────────────────────────
    // When pivot1 == pivot2 (e.g. a perfectly straight vertical/horizontal
    // drop where the child's X equals the parent midpoint X), there is no
    // elbow to round — draw three collinear lineTo calls and return early.
    // Without this guard, addCornerToPath receives len2==0, silently skips
    // the arc, and the final lineTo to `to` is never added → visible gap.
    if ((pivot1 - pivot2).distance < 1.0) {
      // All four points are collinear; just connect them directly.
      path.lineTo(pivot1.dx, pivot1.dy);
      path.lineTo(to.dx, to.dy);
      lines.addAll([
        [from, pivot1],
        [pivot1, to],
      ]);
      return;
    }

    // ── Step 4: normal two-corner rounded path ───────────────────────────
    final double radius = params.cornerRadius;

    void addCornerToPath(Offset start, Offset corner, Offset end) {
      final dx1 = corner.dx - start.dx;
      final dy1 = corner.dy - start.dy;
      final len1 = math.sqrt(dx1 * dx1 + dy1 * dy1);

      final dx2 = end.dx - corner.dx;
      final dy2 = end.dy - corner.dy;
      final len2 = math.sqrt(dx2 * dx2 + dy2 * dy2);

      if (len1 < 1.0 || len2 < 1.0 || radius <= 0.0) {
        path.lineTo(corner.dx, corner.dy);
        return;
      }

      final r = math.min(radius, math.min(len1 / 2, len2 / 2));

      final cornerStartX = corner.dx - (dx1 / len1) * r;
      final cornerStartY = corner.dy - (dy1 / len1) * r;
      path.lineTo(cornerStartX, cornerStartY);

      final cornerEndX = corner.dx + (dx2 / len2) * r;
      final cornerEndY = corner.dy + (dy2 / len2) * r;

      final crossProduct = dx1 * dy2 - dy1 * dx2;

      // ENHANCED GUARD: If points are nearly collinear (straight line) OR
      // if any segment is too short to support a proper corner arc,
      // just draw a straight line to prevent the weird semi-circle "bump".
      if (crossProduct.abs() < 0.5 || len1 < 2.0 || len2 < 2.0) {
        path.lineTo(corner.dx, corner.dy);
        return;
      }

      final isClockwise = crossProduct > 0;

      path.arcToPoint(
        Offset(cornerEndX, cornerEndY),
        radius: Radius.circular(r),
        clockwise: isClockwise,
      );
    }

    addCornerToPath(from, pivot1, pivot2);
    addCornerToPath(pivot1, pivot2, to);
    path.lineTo(to.dx, to.dy);

    lines.addAll([
      [from, pivot2],
      [pivot2, to],
    ]);
  }

  /// Draws a curve starting/ending the handler linearly from the center
  /// of the element.
  void drawCurve(Canvas canvas, Paint paint) {
    var distance = 0.0;
    var dx = 0.0;
    var dy = 0.0;

    final p0 = Offset(from.dx, from.dy);
    final p4 = Offset(to.dx, to.dy);
    distance = (p4 - p0).distance / 3;

    if (params.startArrowPosition.x > 0) {
      dx = distance;
    } else if (params.startArrowPosition.x < 0) {
      dx = -distance;
    }
    if (params.startArrowPosition.y > 0) {
      dy = distance;
    } else if (params.startArrowPosition.y < 0) {
      dy = -distance;
    }
    final p1 = Offset(from.dx + dx, from.dy + dy);
    dx = 0;
    dy = 0;

    if (params.endArrowPosition.x > 0) {
      dx = distance;
    } else if (params.endArrowPosition.x < 0) {
      dx = -distance;
    }
    if (params.endArrowPosition.y > 0) {
      dy = distance;
    } else if (params.endArrowPosition.y < 0) {
      dy = -distance;
    }
    final p3 = params.endArrowPosition == Alignment.center ? Offset(to.dx, to.dy) : Offset(to.dx + dx, to.dy + dy);
    final p2 = Offset(
      p1.dx + (p3.dx - p1.dx) / 2,
      p1.dy + (p3.dy - p1.dy) / 2,
    );

    path
      ..moveTo(p0.dx, p0.dy)
      ..conicTo(p1.dx, p1.dy, p2.dx, p2.dy, 1)
      ..conicTo(p3.dx, p3.dy, p4.dx, p4.dy, 1);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return true;
  }

  @override
  bool? hitTest(Offset position) {
    if (StreamBuilderUtils.isDragging.value) {
      return false;
    } else if (kIsWeb) {
      if (webTimer != null) {
        webTimer?.cancel();
      }
    }

    // Get the line path points
    final points = <Offset>[];
    if (params.style == ArrowStyle.curve) {
      // For curves, sample points along the path
      points.addAll(_sampleCurvePath());
    } else if (params.style == ArrowStyle.segmented) {
      // For segmented lines, use pivot points
      points.add(from);
      for (final pivot in pivots) {
        points.add(pivot.pivot);
      }
      points.add(to);
    } else {
      // For rectangular lines, use the corner points
      points.addAll(_getRectangularPoints());
    }

    // Create a thick stroke around the line for hit testing
    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      // Calculate perpendicular vector for thickness
      final direction = end - start;
      final length = direction.distance;
      if (length == 0) continue;

      final unitDirection = direction / length;
      final perpendicular = Offset(-unitDirection.dy, unitDirection.dx);
      const halfWidth = 2.5;
//      final halfWidth = 3.5;

      // Create a rectangle around the line segment
      final rect = Path()
        ..moveTo(start.dx + perpendicular.dx * halfWidth, start.dy + perpendicular.dy * halfWidth)
        ..lineTo(start.dx - perpendicular.dx * halfWidth, start.dy - perpendicular.dy * halfWidth)
        ..lineTo(end.dx - perpendicular.dx * halfWidth, end.dy - perpendicular.dy * halfWidth)
        ..lineTo(end.dx + perpendicular.dx * halfWidth, end.dy + perpendicular.dy * halfWidth)
        ..close();

      if (rect.contains(position)) {
        print('DrawArrow Line: $start - $end');
        print('DrawArrow Position: $position');
        onLinePressed?.call(position);
        return true;
      }

      // if(isPointOnMiddleLine(start: start, end: end, position: position, width: params.clickableWidth, cutStart: 30, cutEnd: 30)){
      //   onLinePressed?.call(position);
      //   return true;
      // }
    }

    return false;
  }

  bool isPointOnMiddleLine({
    required Offset start,
    required Offset end,
    required double width,
    required Offset position,
    double cutStart = 30, // trim near the start box
    double cutEnd = 30, // trim near the end box
  }) {
    // Direction vector
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return false;

    // Normalize direction
    final ux = dx / length;
    final uy = dy / length;

    // Shorten start and end → avoids overlap with connector circles
    final newStart = Offset(start.dx + ux * cutStart, start.dy + uy * cutStart);
    final newEnd = Offset(end.dx - ux * cutEnd, end.dy - uy * cutEnd);

    // Perpendicular for line thickness
    final px = -uy;
    final py = ux;
    final halfWidth = width / 2;

    // Path only for the trimmed line
    final path = Path()
      ..moveTo(newStart.dx + px * halfWidth, newStart.dy + py * halfWidth)
      ..lineTo(newStart.dx - px * halfWidth, newStart.dy - py * halfWidth)
      ..lineTo(newEnd.dx - px * halfWidth, newEnd.dy - py * halfWidth)
      ..lineTo(newEnd.dx + px * halfWidth, newEnd.dy + py * halfWidth)
      ..close();

    return path.contains(position);
  }

  List<Offset> _sampleCurvePath() {
    final points = <Offset>[];
    const sampleCount = 20;

    for (int i = 0; i <= sampleCount; i++) {
      final t = i / sampleCount;
      points.add(_getCurvePoint(t));
    }

    return points;
  }

  Offset _getCurvePoint(double t) {
    // Recreate the curve calculation from drawCurve method
    var distance = 0.0;
    var dx = 0.0;
    var dy = 0.0;

    final p0 = Offset(from.dx, from.dy);
    final p4 = Offset(to.dx, to.dy);
    distance = (p4 - p0).distance / 3;

    if (params.startArrowPosition.x > 0) {
      dx = distance;
    } else if (params.startArrowPosition.x < 0) {
      dx = -distance;
    }
    if (params.startArrowPosition.y > 0) {
      dy = distance;
    } else if (params.startArrowPosition.y < 0) {
      dy = -distance;
    }
    final p1 = Offset(from.dx + dx, from.dy + dy);
    dx = 0;
    dy = 0;

    if (params.endArrowPosition.x > 0) {
      dx = distance;
    } else if (params.endArrowPosition.x < 0) {
      dx = -distance;
    }
    if (params.endArrowPosition.y > 0) {
      dy = distance;
    } else if (params.endArrowPosition.y < 0) {
      dy = -distance;
    }
    final p3 = params.endArrowPosition == Alignment.center ? Offset(to.dx, to.dy) : Offset(to.dx + dx, to.dy + dy);
    final p2 = Offset(
      p1.dx + (p3.dx - p1.dx) / 2,
      p1.dy + (p3.dy - p1.dy) / 2,
    );

    // Quadratic Bézier curve calculation
    final mt = 1 - t;
    final x = mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx;
    final y = mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy;

    return Offset(x, y);
  }

  bool _isInsideBox(Offset position, FlowElement element, {double margin = 10.0}) {
    final rect = Rect.fromLTWH(
      element.position.dx,
      element.position.dy,
      element.size.width,
      element.size.height,
    ).inflate(margin); // expands rect by margin on all sides

    return rect.contains(position);
  }

  List<Offset> _getRectangularPoints() {
    final points = <Offset>[];

    var pivot1 = from;
    if (params.startArrowPosition.y == 1) {
      pivot1 = Offset(from.dx, from.dy + params.tailLength);
    } else if (params.startArrowPosition.y == -1) {
      pivot1 = Offset(from.dx, from.dy - params.tailLength);
    } else {
      if (to.dy > from.dy) {
        pivot1 = Offset(from.dx, from.dy + params.tailLength);
      } else if (params.startArrowPosition.x != 0) {
        final double sign = params.startArrowPosition.x > 0 ? 1.0 : -1.0;
        pivot1 = Offset(from.dx + sign * params.tailLength, from.dy);
      }
    }

    final Offset pivot2;
    if (params.endArrowPosition.x != 0 && params.endArrowPosition.y == 0) {
      pivot2 = Offset(pivot1.dx, to.dy);
    } else {
      pivot2 = Offset(to.dx, pivot1.dy);
    }

    points.addAll([from, pivot1, pivot2, to]);
    return points;
  }
}

/// Notifier for pivot points.
class PivotsNotifier extends ValueNotifier<List<Pivot>> {
  ///
  PivotsNotifier(super.value) {
    for (final pivot in value) {
      pivot.addListener(notifyListeners);
    }
  }

  /// Add a pivot point.
  void add(Pivot pivot) {
    value.add(pivot);
    pivot.addListener(notifyListeners);
    notifyListeners();
  }

  /// Remove a pivot point.
  void remove(Pivot pivot) {
    value.remove(pivot);
    pivot.removeListener(notifyListeners);
    notifyListeners();
  }

  /// Insert a pivot point.
  void insert(int index, Pivot pivot) {
    value.insert(index, pivot);
    pivot.addListener(notifyListeners);
    notifyListeners();
  }

  /// Remove a pivot point by its index.
  void removeAt(int index) {
    value.removeAt(index).removeListener(notifyListeners);
    notifyListeners();
  }
}
