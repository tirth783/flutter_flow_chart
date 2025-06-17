// ignore_for_file: avoid_positional_boolean_parameters, avoid_dynamic_calls
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
// ignore_for_file: use_setters_to_change_properties

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_flow_chart/flutter_flow_chart.dart';
import 'package:flutter_flow_chart/src/elements/connection_params.dart';
import 'package:uuid/uuid.dart';

/// Kinf od element
enum ElementKind {
  ///
  rectangle,

  ///
  diamond,

  ///
  storage,

  ///
  oval,

  ///
  parallelogram,

  ///
  hexagon,

  ///
  image,
}

/// Handler supported by elements
enum Handler {
  ///
  topCenter,

  ///
  bottomCenter,

  ///
  rightCenter,

  ///
  leftCenter;

  /// Convert to [Alignment]
  Alignment toAlignment() {
    switch (this) {
      case Handler.topCenter:
        return Alignment.topCenter;
      case Handler.bottomCenter:
        return Alignment.bottomCenter;
      case Handler.rightCenter:
        return Alignment.centerRight;
      case Handler.leftCenter:
        return Alignment.centerLeft;
    }
  }
}

/// Class to store [FlowElement]s and notify its changes
class FlowElement extends ChangeNotifier {
  ///
  FlowElement({
    Offset position = Offset.zero,
    this.size = Size.zero,
    this.text = '',
    this.subText = '',
    this.textColor = Colors.black,
    this.subTextColor = Colors.grey,
    this.fontFamily,
    this.textSize = 24,
    this.subTextSize = 12,
    this.textIsBold = false,
    this.kind = ElementKind.rectangle,
    this.handlers = const [
      Handler.topCenter,
      Handler.bottomCenter,
      Handler.rightCenter,
      Handler.leftCenter,
    ],
    this.handlerSize = 15.0,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.blue,
    this.borderThickness = 3,
    this.elevation = 4,
    this.data,
    this.serializedData,
    this.isDraggable = true,
    this.isResizable = false,
    this.isConnectable = true,
    this.isDeletable = false,
    List<ConnectionParams>? next,
  })  : next = next ?? [],
        id = const Uuid().v4(),
        isEditingText = false,
        // fixing offset issue under extreme scaling
        position = position -
            Offset(
              size.width / 2 + handlerSize / 2,
              size.height / 2 + handlerSize / 2,
            );

  ///
  factory FlowElement.fromMap(Map<String, dynamic> map) {
    final e = FlowElement(
      size: Size(
        (map['size.width'] as num).toDouble(),
        (map['size.height'] as num).toDouble(),
      ),
      text: map['text'] as String,
      subText: map['subText'] as String,
      textColor: Color(map['textColor'] as int),
      subTextColor: Color(map['subTextColor'] as int),
      fontFamily: map['fontFamily'] as String?,
      textSize: (map['textSize'] as num).toDouble(),
      subTextSize: (map['subTextSize'] as num).toDouble(),
      textIsBold: map['textIsBold'] as bool,
      kind: ElementKind.values[map['kind'] as int],
      handlers: List<Handler>.from(
        (map['handlers'] as List<dynamic>).map<Handler>(
          (x) => Handler.values[x as int],
        ),
      ),
      handlerSize: (map['handlerSize'] as num).toDouble(),
      backgroundColor: Color(map['backgroundColor'] as int),
      borderColor: Color(map['borderColor'] as int),
      borderThickness: (map['borderThickness'] as num).toDouble(),
      elevation: (map['elevation'] as num).toDouble(),
      next: (map['next'] as List).isNotEmpty
          ? List<ConnectionParams>.from(
              (map['next'] as List<dynamic>).map<dynamic>(
                (x) => ConnectionParams.fromMap(x as Map<String, dynamic>),
              ),
            )
          : [],
      isDraggable: map['isDraggable'] as bool? ?? true,
      isResizable: map['isResizable'] as bool? ?? false,
      isConnectable: map['isConnectable'] as bool? ?? true,
      isDeletable: map['isDeletable'] as bool? ?? false,
    )
      ..setId(map['id'] as String)
      ..position = Offset(
        (map['positionDx'] as num).toDouble(),
        (map['positionDy'] as num).toDouble(),
      )
      ..serializedData = map['data'] as String?;
    return e;
  }

  ///
  factory FlowElement.fromJson(String source) =>
      FlowElement.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Unique id set when adding a [FlowElement] with [Dashboard.addElement()]
  String id;

  /// The position of the [FlowElement]
  Offset position;

  /// The size of the [FlowElement]
  Size size;

  /// Element text
  String text;

  /// Element subText
  String subText;

  /// Text color
  Color textColor;

  /// subTextColor color
  Color subTextColor;

  /// Text font family
  String? fontFamily;

  /// Text size
  double textSize;

  /// subTextSize
  double subTextSize;

  /// Makes text bold if true
  bool textIsBold;

  /// Element shape
  ElementKind kind;

  /// Connection handlers
  List<Handler> handlers;

  /// The size of element handlers
  double handlerSize;

  /// Background color of the element
  Color backgroundColor;

  /// Border color of the element
  Color borderColor;

  /// Border thickness of the element
  double borderThickness;

  /// Shadow elevation
  double elevation;

  /// List of connections from this element
  List<ConnectionParams> next;

  /// Whether this element can be dragged around
  bool isDraggable;

  /// Whether this element can be resized
  bool isResizable;

  /// Whether this element can be deleted quickly by clicking on the trash icon
  bool isDeletable;

  /// Whether this element can be connected to others
  bool isConnectable;

  /// Whether the text of this element is being edited with a form field
  bool isEditingText;

  /// Kind-specific data
  final dynamic data;

  /// Kind-specific data to load/save
  String? serializedData;

  @override
  String toString() {
    return 'FlowElement{kind: $kind, text: $text, subText: $subText}';
  }

  /// Get the handler center of this handler for the given alignment.
  Offset getHandlerPosition(Alignment alignment) {
    // The zero position coordinate is the top-left of this element.
    final ret = Offset(
      position.dx + (size.width * ((alignment.x + 1) / 2)) + handlerSize / 2,
      position.dy + (size.height * ((alignment.y + 1) / 2) + handlerSize / 2),
    );
    return ret;
  }

  /// Sets a new scale
  void setScale(double currentZoom, double factor) {
    size = size / currentZoom * factor;
    handlerSize = handlerSize / currentZoom * factor;
    textSize = textSize / currentZoom * factor;
    subTextSize = subTextSize / currentZoom * factor;
    for (final element in next) {
      element.arrowParams.setScale(currentZoom, factor);
    }

    notifyListeners();
  }

  /// Used internally to set an unique Uuid to this element
  void setId(String id) => this.id = id;

  /// Set text
  void setText(String text) {
    this.text = text;
    notifyListeners();
  }

  /// Set subText
  void setsubText(String subText) {
    this.subText = subText;
    notifyListeners();
  }

  /// Set text color
  void setTextColor(Color color) {
    textColor = color;
    notifyListeners();
  }

  /// Set subTextColor color
  void setSubTextColor(Color color) {
    subTextColor = color;
    notifyListeners();
  }

  /// Set text font family
  void setFontFamily(String? fontFamily) {
    this.fontFamily = fontFamily;
    notifyListeners();
  }

  /// Set text size
  void setTextSize(double size) {
    textSize = size;
    notifyListeners();
  }

  /// subTextSize
  void setSubTextSize(double size) {
    subTextSize = size;
    notifyListeners();
  }

  /// Set text bold
  void setTextIsBold(bool isBold) {
    textIsBold = isBold;
    notifyListeners();
  }

  /// Set background color
  void setBackgroundColor(Color color) {
    backgroundColor = color;
    notifyListeners();
  }

  /// Set border color
  void setBorderColor(Color color) {
    borderColor = color;
    notifyListeners();
  }

  /// Set border thickness
  void setBorderThickness(double thickness) {
    borderThickness = thickness;
    notifyListeners();
  }

  /// Set elevation
  void setElevation(double elevation) {
    this.elevation = elevation;
    notifyListeners();
  }

  /// Change element position in the dashboard
  void changePosition(Offset newPosition) {
    position = newPosition;
    notifyListeners();
  }

  /// Change element size
  void changeSize(Size newSize) {
    size = newSize;
    if (size.width < 40) size = Size(40, size.height);
    if (size.height < 40) size = Size(size.width, 40);
    notifyListeners();
  }

  @override
  bool operator ==(covariant FlowElement other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.serializedData == serializedData &&
        other.data == data;
  }

  @override
  int get hashCode {
    return position.hashCode ^
        size.hashCode ^
        text.hashCode ^
        subText.hashCode ^
        textColor.hashCode ^
        subTextColor.hashCode ^
        fontFamily.hashCode ^
        textSize.hashCode ^
        subTextSize.hashCode ^
        textIsBold.hashCode ^
        id.hashCode ^
        kind.hashCode ^
        handlers.hashCode ^
        handlerSize.hashCode ^
        backgroundColor.hashCode ^
        borderColor.hashCode ^
        borderThickness.hashCode ^
        elevation.hashCode ^
        next.hashCode ^
        isResizable.hashCode ^
        isConnectable.hashCode ^
        isDeletable.hashCode ^
        data.hashCode ^
        serializedData.hashCode;
  }

  ///
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'positionDx': position.dx,
      'positionDy': position.dy,
      'size.width': size.width,
      'size.height': size.height,
      'text': text,
      'subText': subText,
      'textColor': textColor.value,
      'subTextColor': subTextColor.value,
      'fontFamily': fontFamily,
      'textSize': textSize,
      'subTextSize': subTextSize,
      'textIsBold': textIsBold,
      'id': id,
      'kind': kind.index,
      'handlers': handlers.map((x) => x.index).toList(),
      'handlerSize': handlerSize,
      'backgroundColor': backgroundColor.value,
      'borderColor': borderColor.value,
      'borderThickness': borderThickness,
      'elevation': elevation,
      'data': serializedData,
      'next': next.map((x) => x.toMap()).toList(),
      'isDraggable': isDraggable,
      'isResizable': isResizable,
      'isConnectable': isConnectable,
      'isDeletable': isDeletable,
    };
  }

  ///
  String toJson() => json.encode(toMap());

  /// Set serialized data
  void setSerializedData(String? data) {
    serializedData = data;
    notifyListeners();
  }
}
