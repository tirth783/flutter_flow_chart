import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:flutter_flow_chart/src/objects/diamond_widget.dart';
import 'package:flutter_flow_chart/src/objects/hexagon_widget.dart';
import 'package:flutter_flow_chart/src/objects/image_widget.dart';
import 'package:flutter_flow_chart/src/objects/oval_widget.dart';
import 'package:flutter_flow_chart/src/objects/parallelogram_widget.dart';
import 'package:flutter_flow_chart/src/objects/rectangle_widget.dart';
import 'package:flutter_flow_chart/src/objects/storage_widget.dart';
import 'package:flutter_flow_chart/src/ui/element_handlers.dart';
import 'package:flutter_flow_chart/src/ui/handler_widget.dart';
import 'dart:math' as math;

/// Fixed size (logical px) of the delete handle. Does not change with zoom.
const double _kDeleteHandleScreenSize = 28.0;

/// Widget that use [element] properties to display it on the dashboard scene
class ElementWidget extends StatefulWidget {
  ///
  const ElementWidget({
    required this.dashboard,
    required this.element,
    super.key,
    this.onElementPressed,
    this.onElementDeletePressed,
    this.onElementSecondaryTapped,
    this.onElementLongPressed,
    this.onElementSecondaryLongTapped,
    this.onHandlerPressed,
    this.onHandlerSecondaryTapped,
    this.onHandlerLongPressed,
    this.onHandlerSecondaryLongTapped,
  });

  ///
  final Dashboard dashboard;

  ///
  final FlowElement element;

  ///
  final void Function(BuildContext context, Offset position)? onElementPressed;
  final void Function(BuildContext context, Offset position)? onElementDeletePressed;

  ///
  final void Function(BuildContext context, Offset position)? onElementSecondaryTapped;

  ///
  final void Function(BuildContext context, Offset position)? onElementLongPressed;

  ///
  final void Function(BuildContext context, Offset position)? onElementSecondaryLongTapped;

  ///
  final void Function(
    BuildContext context,
    Offset position,
    Handler handler,
    FlowElement element,
  )? onHandlerPressed;

  ///
  final void Function(
    BuildContext context,
    Offset position,
    Handler handler,
    FlowElement element,
  )? onHandlerSecondaryTapped;

  ///
  final void Function(
    BuildContext context,
    Offset position,
    Handler handler,
    FlowElement element,
  )? onHandlerLongPressed;

  ///
  final void Function(
    BuildContext context,
    Offset position,
    Handler handler,
    FlowElement element,
  )? onHandlerSecondaryLongTapped;

  @override
  State<ElementWidget> createState() => _ElementWidgetState();
}

class _ElementWidgetState extends State<ElementWidget> {
  // local widget touch position when start dragging
  Offset delta = Offset.zero;
  late Size elementStartSize;
  Offset tapLocation = Offset.zero;
  Offset secondaryTapDownPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    widget.element.addListener(_elementChanged);
  }

  @override
  void dispose() {
    widget.element.removeListener(_elementChanged);
    super.dispose();
  }

  void _elementChanged() {
    setState(() {});
  }

  String _getImageKey(FlowElement element) {
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
    return 'default';
  }

  @override
  Widget build(BuildContext context) {
    Widget element;

    switch (widget.element.kind) {
      case ElementKind.diamond:
        element = DiamondWidget(
          key: ValueKey(widget.element.id),
          element: widget.element,
        );
      case ElementKind.storage:
        element = StorageWidget(
          key: ValueKey(widget.element.id),
          element: widget.element,
        );
      case ElementKind.oval:
        element = OvalWidget(
          key: ValueKey(widget.element.id),
          element: widget.element,
        );
      case ElementKind.parallelogram:
        element = ParallelogramWidget(
          key: ValueKey(widget.element.id),
          element: widget.element,
        );
      case ElementKind.hexagon:
        element = HexagonWidget(
          key: ValueKey(widget.element.id),
          element: widget.element,
        );
      case ElementKind.rectangle:
        element = RectangleWidget(
          key: ValueKey(widget.element.id),
          element: widget.element,
          pressDelete: () {
            var tapLocation = Offset.zero;
            widget.onElementDeletePressed?.call(context, tapLocation);
          },
        );
      case ElementKind.image:
        // Create stable key based on element ID and image source to prevent unnecessary rebuilds
        final imageKey = _getImageKey(widget.element);
        element = ImageWidget(
          key: ValueKey('${widget.element.id}_$imageKey'),
          element: widget.element,
          pressDelete: () {
            var tapLocation = Offset.zero;
            widget.onElementDeletePressed?.call(context, tapLocation);
          },
        );
    }

    // switch (widget.element.kind) {
    //   case ElementKind.diamond:
    //     element = DiamondWidget(element: widget.element);
    //   case ElementKind.storage:
    //     element = StorageWidget(element: widget.element);
    //   case ElementKind.oval:
    //     element = OvalWidget(element: widget.element);
    //   case ElementKind.parallelogram:
    //     element = ParallelogramWidget(element: widget.element);
    //   case ElementKind.hexagon:
    //     element = HexagonWidget(element: widget.element);
    //   case ElementKind.rectangle:
    //     element = RectangleWidget(element: widget.element);
    //   case ElementKind.image:
    //     element = Stack(
    //       alignment: Alignment.center, // Add this to center the image
    //       children: [
    //         // Add rectangle as background
    //         RectangleWidget(element: widget.element),
    //         // Add image on top with proper sizing
    //         Padding(
    //           padding: const EdgeInsets.all(8.0), // Add padding to keep image inside rectangle
    //           child: ImageWidget(element: widget.element),
    //         ),
    //       ],
    //     );
    // }

    if (widget.element.isConnectable && widget.element.handlers.isNotEmpty) {
      element = ElementHandlers(
        dashboard: widget.dashboard,
        element: widget.element,
        handlerSize: widget.element.handlerSize,
        onHandlerPressed: widget.onHandlerPressed,
        onHandlerSecondaryTapped: widget.onHandlerSecondaryTapped,
        onHandlerLongPressed: widget.onHandlerLongPressed,
        onHandlerSecondaryLongTapped: widget.onHandlerSecondaryLongTapped,
        child: element,
      );
    } else {
      element = Padding(
        padding: EdgeInsets.all(widget.element.handlerSize / 2),
        child: element,
      );
    }

    if (widget.element.isDraggable) {
      // Element is draggable: wrap with drag logic
      element = _buildDraggableWidget(element);
    } else {
      // Element is not draggable: keep it interactive for taps,
      // but do not allow dragging the element itself.
      // (Grid panning is still handled by the background gestures.)
    }

    element = GestureDetector(
      onTapDown: (details) => tapLocation = details.globalPosition,
      onSecondaryTapDown: (details) => secondaryTapDownPos = details.globalPosition,
      onTap: () {
        widget.onElementPressed?.call(context, tapLocation);
      },
      onSecondaryTap: () {
        widget.onElementSecondaryTapped?.call(context, secondaryTapDownPos);
      },
      onLongPress: () {
        widget.onElementLongPressed?.call(context, tapLocation);
      },
      onSecondaryLongPress: () {
        widget.onElementSecondaryLongTapped?.call(context, secondaryTapDownPos);
      },
      child: element,
    );

    // Reserve enough space so *all* handles fit inside the widget bounds.
    // Delete handle uses fixed size (_kDeleteHandleScreenSize) — no change with zoom.
    final baseHandlerSize = widget.element.handlerSize;
    final resizeHandleSize = widget.element.isResizable ? baseHandlerSize * 1.5 : baseHandlerSize;
    final deleteHandleSize = widget.element.isDeletable ? _kDeleteHandleScreenSize : 0.0;
    final reservedHandleSize = math.max(
      baseHandlerSize,
      math.max(resizeHandleSize, deleteHandleSize),
    );
    final extraInset = (reservedHandleSize - baseHandlerSize) / 2;

    return Transform.translate(
      offset: widget.element.position,
      child: SizedBox(
        width: widget.element.size.width + reservedHandleSize,
        height: widget.element.size.height + reservedHandleSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.all(extraInset),
              child: element,
            ),
            if (widget.element.isResizable) _buildResizeHandle(reservedHandleSize),
            if (widget.element.isDeletable) _buildDeleteHandle(reservedHandleSize),
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle(double reservedHandleSize) {
    final handleSize = widget.element.handlerSize * 1.5;
    return Positioned(
      right: reservedHandleSize / 2 - handleSize / 2,
      bottom: reservedHandleSize / 2 - handleSize / 2,
      child: Listener(
        onPointerDown: (event) {
          elementStartSize = widget.element.size;
        },
        onPointerMove: (event) {
          elementStartSize += event.localDelta;
          widget.element.changeSize(elementStartSize);
        },
        child: HandlerWidget(
          width: handleSize,
          height: handleSize,
          icon: const Icon(Icons.compare_arrows),
        ),
      ),
    );
  }

  Widget _buildDeleteHandle(double reservedHandleSize) {
    // Fixed size in logical pixels — does not increase or decrease with zoom.
    final handleSize = _kDeleteHandleScreenSize;
    return Positioned(
      right: reservedHandleSize / 2 - handleSize / 2,
      bottom: reservedHandleSize / 2 - handleSize / 2,
      child: Listener(
        onPointerUp: (event) {
          // widget.dashboard.removeElement(widget.element);
          widget.onElementDeletePressed?.call(context, tapLocation);
        },
        child: HandlerWidget(
          width: handleSize,
          height: handleSize,
          isBorderNeeded: false,
          icon: const Icon(Icons.remove_circle_rounded),
        ),
      ),
    );
  }

  Widget _buildDraggableWidget(Widget element) {
    return Listener(
      onPointerDown: (event) {
        delta = event.localPosition;
      },
      child: Draggable<FlowElement>(
        data: widget.element,
        childWhenDragging: const SizedBox.shrink(),
        feedback: Material(color: Colors.transparent, child: element),
        child: element,
        onDragUpdate: (details) {
          widget.element.changePosition(
            details.globalPosition - widget.dashboard.position - delta,
          );
        },
        onDragEnd: (details) {
          widget.element.changePosition(
            details.offset - widget.dashboard.position,
          );
        },
      ),
    );
  }
}
