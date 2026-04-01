import 'package:flutter/material.dart';

/// Defines grid parameters.
class GridBackgroundParams extends ChangeNotifier {
  /// [gridSquare] is the raw size of the grid square when scale is 1
  GridBackgroundParams({
    double gridSquare = 22.0,
    this.gridThickness = 0.5,
    this.secondarySquareStep = 4,
    Color? backgroundColor,
    Color? gridColor,
    void Function(double scale)? onScaleUpdate,
  })  : rawGridSquareSize = gridSquare,
        backgroundColor = backgroundColor ?? const Color(0xFFF9FAFD),
        gridColor = gridColor ?? const Color(0xFFE9EDF5) {
    if (onScaleUpdate != null) {
      _onScaleUpdateListeners.add(onScaleUpdate);
    }
  }

  ///
  factory GridBackgroundParams.fromMap(Map<String, dynamic> map) {
    // Parse offset - handle both nested {offset: {dx, dy}} and flat {offset.dx, offset.dy} formats
    double offsetDx = 0.0;
    double offsetDy = 0.0;

    if (map['offset'] != null && map['offset'] is Map) {
      // Nested format: {offset: {dx: ..., dy: ...}}
      final offsetMap = map['offset'] as Map<String, dynamic>;
      offsetDx = ((offsetMap['dx'] ?? 0.0) as num).toDouble();
      offsetDy = ((offsetMap['dy'] ?? 0.0) as num).toDouble();
    } else {
      // Flat format: {offset.dx: ..., offset.dy: ...}
      offsetDx = ((map['offset.dx'] ?? 0.0) as num).toDouble();
      offsetDy = ((map['offset.dy'] ?? 0.0) as num).toDouble();
    }

    final params = GridBackgroundParams(
      gridSquare: ((map['gridSquare'] ?? 20.0) as num).toDouble(),
      gridThickness: ((map['gridThickness'] ?? 0.0) as num).toDouble(),
      secondarySquareStep: map['secondarySquareStep'] as int? ?? 5,
      backgroundColor: Color(
        map['backgroundColor'] as int? ?? 0xFFFFFFFF,
      ),
      gridColor: Color(map['gridColor'] as int? ?? 0x00000000),
    )
      ..scale = ((map['scale'] ?? 1.0) as num).toDouble()
      .._offset = Offset(offsetDx, offsetDy);

    return params;
  }

  /// Unscaled size of the grid square
  /// i.e. the size of the square when scale is 1
  final double rawGridSquareSize;

  /// Thickness of lines.
  final double gridThickness;

  /// How many vertical or horizontal lines to draw the marked lines.
  final int secondarySquareStep;

  /// Grid background color.
  final Color backgroundColor;

  /// Grid lines color.
  final Color gridColor;

  /// offset to move the grid
  Offset _offset = Offset.zero;

  /// Scale of the grid.
  double scale = 1;

  /// Add listener for scaling
  void addOnScaleUpdateListener(void Function(double scale) listener) {
    _onScaleUpdateListeners.add(listener);
  }

  /// Remove listener for scaling
  void removeOnScaleUpdateListener(void Function(double scale) listener) {
    _onScaleUpdateListeners.remove(listener);
  }

  final List<void Function(double scale)> _onScaleUpdateListeners = [];

  ///
  set offset(Offset delta) {
    _offset += delta;
    notifyListeners();
  }

  /// Set the absolute offset value (not delta)
  void setOffset(Offset newOffset) {
    _offset = newOffset;
    notifyListeners();
  }

  ///
  void setScale(double factor, Offset focalPoint) {
    _offset = Offset(
      focalPoint.dx * (1 - factor),
      focalPoint.dy * (1 - factor),
    );
    scale = factor;

    for (final listener in _onScaleUpdateListeners) {
      listener(scale);
    }
    notifyListeners();
  }

  /// size of the grid square with scale applied
  double get gridSquare => rawGridSquareSize * scale;

  ///
  Offset get offset => _offset;

  ///
  Map<String, dynamic> toMap() {
    return {
      'offset': {'dx': _offset.dx, 'dy': _offset.dy},
      'scale': scale,
      'gridSquare': rawGridSquareSize,
      'gridThickness': gridThickness,
      'secondarySquareStep': secondarySquareStep,
      'backgroundColor': backgroundColor.value,
      'gridColor': gridColor.value,
    };
  }
}

/// Uses a CustomPainter to draw a grid with the given parameters
class GridBackground extends StatelessWidget {
  ///
  GridBackground({super.key, GridBackgroundParams? params}) : params = params ?? GridBackgroundParams();

  /// Grid parameters
  final GridBackgroundParams params;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: params,
      builder: (context, _) {
        return RepaintBoundary(
          child: CustomPaint(
            painter: _GridBackgroundPainter(
              params: params,
              dx: params.offset.dx,
              dy: params.offset.dy,
            ),
          ),
        );
      },
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  _GridBackgroundPainter({
    required this.params,
    required this.dx,
    required this.dy,
  });

  final GridBackgroundParams params;
  final double dx;
  final double dy;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      // Background
      ..color = params.backgroundColor;
    canvas.drawRect(
      Rect.fromPoints(Offset.zero, Offset(size.width, size.height)),
      paint,
    );

    // Forcefully show grid for all trees (ignore saved backend settings if transparent)
    final Color activeGridColor = params.gridColor.alpha == 0 
        ? const Color(0xFFE9EDF5) // Default light grey for diamonds
        : params.gridColor;

    // Calculate the starting points for x and y
    double step = params.gridSquare * params.secondarySquareStep / 2;
    if (step <= 0) {
      step = 22.0 * 2; // Fallback step if zero from legacy data
    }

    final startX = dx % step;
    final startY = dy % step;

    // Calculate the number of points to draw outside the visible area
    const extraLines = 1;

    // Diamond size
    final diamondRadius = 3.0 * params.scale;

    paint
      ..color = activeGridColor
      ..style = PaintingStyle.fill;

    // Draw diamond grid
    for (var x = startX - extraLines * step; x < size.width + extraLines * step; x += step) {
      for (var y = startY - extraLines * step; y < size.height + extraLines * step; y += step) {
        final path = Path()
          ..moveTo(x, y - diamondRadius)
          ..lineTo(x + diamondRadius, y)
          ..lineTo(x, y + diamondRadius)
          ..lineTo(x - diamondRadius, y)
          ..close();
        
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridBackgroundPainter oldDelegate) {
    debugPrint('shouldRepaint ${oldDelegate.dx} $dx ${oldDelegate.dy} $dy');
    return oldDelegate.dx != dx || oldDelegate.dy != dy;
  }
}
