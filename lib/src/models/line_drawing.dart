import 'package:flutter/material.dart';

enum LineStyle {
  solid,
  dotted,
  dashed,
}

enum LineRange {
  open,
  close,
  leftOpen,
  rightOpen,
}

class LineDrawing {
  late final DateTime leftX;
  late final DateTime rightX;
  late final double leftY; // price
  late final double rightY; // price
  late LineStyle lineStyle;
  late LineRange lineRange;
  double? lineWidth;
  late Color lineColor;
  late String text;
  late double textSize;
  late Color textColor;

  LineDrawing({
    required this.leftX,
    required this.rightX,
    required this.leftY,
    required this.rightY,
    this.lineStyle = LineStyle.solid,
    this.lineRange = LineRange.close,
    this.lineWidth = 1.0,
    this.lineColor = Colors.black,
    this.text = "",
    this.textSize = 12.0,
    this.textColor = Colors.black,
  });
}
