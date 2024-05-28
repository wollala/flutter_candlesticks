import 'dart:math' as math;

import 'package:candlesticks/src/models/main_window_indicator.dart';
import 'package:flutter/material.dart';

import '../../candlesticks.dart';

class MainWindowIndicatorWidget extends LeafRenderObjectWidget {
  final List<Candle> candles;
  final List<IndicatorComponentData> indicatorDatas;
  final int index; // 가장 오른쪽 캔들 인덱스(여백 포함하기 위해 음수도 가능함)
  final double candleWidth;
  final double high;
  final double low;
  final List<LineDrawing> drawing;

  MainWindowIndicatorWidget({
    required this.candles,
    required this.indicatorDatas,
    required this.index,
    required this.candleWidth,
    required this.low,
    required this.high,
    required this.drawing,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return MainWindowIndicatorRenderObject(
      candles,
      indicatorDatas,
      index,
      candleWidth,
      low,
      high,
      drawing,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {
    MainWindowIndicatorRenderObject candlestickRenderObject = renderObject as MainWindowIndicatorRenderObject;

    candlestickRenderObject._candles = candles;
    candlestickRenderObject._indicatorDatas = indicatorDatas;
    candlestickRenderObject._index = index;
    candlestickRenderObject._candleWidth = candleWidth;
    candlestickRenderObject._high = high;
    candlestickRenderObject._low = low;
    candlestickRenderObject.markNeedsPaint();
    super.updateRenderObject(context, renderObject);
  }
}

class MainWindowIndicatorRenderObject extends RenderBox {
  late List<Candle> _candles;
  late List<LineDrawing> _drawing;
  late List<IndicatorComponentData> _indicatorDatas;
  late int _index;
  late double _candleWidth;
  late double _low;
  late double _high;

  MainWindowIndicatorRenderObject(
    List<Candle> candles,
    List<IndicatorComponentData> indicatorDatas,
    int index,
    double candleWidth,
    double low,
    double high,
    List<LineDrawing> drawing,
  ) {
    _candles = candles;
    _indicatorDatas = indicatorDatas;
    _index = index;
    _candleWidth = candleWidth;
    _low = low;
    _high = high;
    _drawing = drawing;
  }

  /// set size as large as possible
  @override
  void performLayout() {
    size = Size(constraints.maxWidth, constraints.maxHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    double range = (_high - _low) / size.height;

    _indicatorDatas.forEach((element) {
      if (element.visible == false) {
        return;
      }
      Path? path;
      for (int i = 0; (i + 1) * _candleWidth < size.width; i++) {
        if (i + _index >= element.values.length || i + _index < 0 || element.values[i + _index] == null) continue;

        if (path == null) {
          path = Path()
            ..moveTo(size.width + offset.dx - (i + 0.5) * _candleWidth,
                offset.dy + (_high - element.values[i + _index]!) / range);
        } else {
          path.lineTo(size.width + offset.dx - (i + 0.5) * _candleWidth,
              offset.dy + (_high - element.values[i + _index]!) / range);
        }
      }
      if (path != null)
        context.canvas.drawPath(
            path,
            Paint()
              ..color = element.color
              ..strokeWidth = 1
              ..style = PaintingStyle.stroke);
    });

    for (LineDrawing lineDrawing in _drawing) {
      int startCandleIndex = _candles.indexWhere((element) => element.isContain(lineDrawing.leftX));
      int endCandleIndex = _candles.indexWhere((element) => element.isContain(lineDrawing.rightX));

      var xlast = size.width + offset.dx - (endCandleIndex - _index + 0.5) * _candleWidth;
      var xfirst = size.width + offset.dx - (startCandleIndex - _index + 0.5) * _candleWidth;

      var ylast = offset.dy + (_high - lineDrawing.rightY) / range;
      var yfirst = offset.dy + (_high - lineDrawing.leftY) / range;

      var dx = xlast - xfirst;
      var dy = ylast - yfirst;

      var alpha = dy / dx;
      var beta = yfirst - alpha * xfirst;

      late Offset open;
      late Offset close;
      switch (lineDrawing.lineRange) {
        case LineRange.open:
          open = Offset(
            offset.dx,
            (alpha * offset.dx + beta),
          );

          close = Offset(
            offset.dx + size.width,
            (alpha * (offset.dx + size.width) + beta),
          );
          break;
        case LineRange.close:
          open = Offset(
            xfirst,
            yfirst,
          );
          close = Offset(
            xlast,
            ylast,
          );
          break;
        case LineRange.leftOpen:
          open = Offset(
            offset.dx,
            (alpha * offset.dx + beta),
          );
          close = Offset(
            xlast,
            ylast,
          );
          break;
        case LineRange.rightOpen:
          open = Offset(
            xfirst,
            yfirst,
          );
          close = Offset(
            offset.dx + size.width,
            (alpha * (offset.dx + size.width) + beta),
          );
          break;
      }
      switch (lineDrawing.lineStyle) {
        case LineStyle.solid:
          context.canvas.drawLine(
              open,
              close,
              Paint()
                ..color = lineDrawing.lineColor
                ..strokeWidth = lineDrawing.lineWidth!
                ..style = PaintingStyle.stroke);
          break;
        case LineStyle.dotted:
          context.canvas.drawDashLine(
              open,
              close,
              Paint()
                ..color = lineDrawing.lineColor
                ..strokeWidth = lineDrawing.lineWidth!
                ..style = PaintingStyle.stroke,
              width: lineDrawing.lineWidth,
              space: lineDrawing.lineWidth);
          break;
        case LineStyle.dashed:
          context.canvas.drawDashLine(
              open,
              close,
              Paint()
                ..color = lineDrawing.lineColor
                ..strokeWidth = lineDrawing.lineWidth!
                ..style = PaintingStyle.stroke,
              width: 15,
              space: 10);
          break;
      }

      // 텍스트 설정
      final textSpan = TextSpan(
        text: '${lineDrawing.text} ${lineDrawing.rightY}',
        style: TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: size.width,
      );

      // 텍스트가 들어갈 사각형의 위치와 크기 설정
      late double horizontalOffset;
      switch (lineDrawing.lineRange) {
        case LineRange.open:
          horizontalOffset = size.width - textPainter.width - 2;
          break;
        case LineRange.close:
          horizontalOffset = size.width - textPainter.width - 2;
          break;
        case LineRange.leftOpen:
          horizontalOffset = 2;
          break;
        case LineRange.rightOpen:
          horizontalOffset = size.width - textPainter.width - 2;
          break;
      }

      final textOffset = Offset(horizontalOffset, ylast - textPainter.height / 2);
      final rect = Rect.fromLTWH(textOffset.dx - 2, textOffset.dy, textPainter.width + 4, textPainter.height);

      // 사각형 그리기
      context.canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      ); // 사각형 내부 채우기
      context.canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.black
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      ); // 사각형 테두리

      // 텍스트 그리기
      textPainter.paint(
        context.canvas,
        textOffset,
      );
      continue;
    }
    context.canvas.save();
    context.canvas.restore();
  }
}

extension CustomLine on Canvas {
  drawDashLine(
    Offset offset1,
    Offset offset2,
    Paint paint, {
    double? width,
    double? space,
  }) {
    var distance = offset1.distanceTo(offset2);
    var dashWidth = width ?? 20.0;
    var dashSpace = space ?? 20.0;
    var dashCount = (distance / (dashWidth + dashSpace)).floor();
    for (var i = 0; i < dashCount; i++) {
      var startX = offset1.dx + ((offset2.dx - offset1.dx) / dashCount) * i;
      var startY = offset1.dy + ((offset2.dy - offset1.dy) / dashCount) * i;
      var endX = startX + (offset2.dx - offset1.dx) * (dashWidth / distance);
      var endY = startY + (offset2.dy - offset1.dy) * (dashWidth / distance);

      drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }
}

extension OffsetDis on Offset {
  distanceTo(Offset other) {
    var dx = other.dx - this.dx;
    var dy = other.dy - this.dy;
    return math.sqrt(dx * dx + dy * dy);
  }
}
