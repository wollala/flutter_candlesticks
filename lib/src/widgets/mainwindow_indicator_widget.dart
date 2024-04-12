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

  MainWindowIndicatorWidget({
    required this.candles,
    required this.indicatorDatas,
    required this.index,
    required this.candleWidth,
    required this.low,
    required this.high,
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
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    MainWindowIndicatorRenderObject candlestickRenderObject =
        renderObject as MainWindowIndicatorRenderObject;

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
  ) {
    _candles = candles;
    _indicatorDatas = indicatorDatas;
    _index = index;
    _candleWidth = candleWidth;
    _low = low;
    _high = high;
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
        if (i + _index >= element.values.length ||
            i + _index < 0 ||
            element.values[i + _index] == null) continue;

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

    double targetPrice = 0.05048;
    DateTime targetTime = DateTime(2024, 4, 11, 23, 33, 00);
    Duration? interval;
    DateTime? startTime;
    DateTime? endTime;
    for (int i = 0; (i + 1) * _candleWidth < size.width; i++) {
      if (i + _index >= _candles.length || i + _index < 0) continue;

      var curCandle = _candles[i + _index];
      var nextCandle = _candles[i + _index + 1];

      if (interval == null)
        interval = curCandle.date.difference(nextCandle.date);
      startTime = curCandle.date;
      endTime = curCandle.date.add(interval);

      if (targetTime.isAfter(startTime) && targetTime.isBefore(endTime) ||
          targetTime.isAtSameMomentAs(startTime) ||
          targetTime.isAfter(_candles[_index].date)) {
        //targetTime.isAfter(_candles[_index].date) 이 상황부터 중복으로 그려짐. 중복 painting 제거하기
        double startX = 0;
        double endX = size.width + offset.dx - i * _candleWidth;

        double startY = offset.dy + (_high - targetPrice) / range;
        double endY = startY;

        Offset start = Offset(startX, startY);
        Offset end = Offset(endX, endY);

        // 선 그리기
        context.canvas.drawLine(
          start,
          end,
          Paint()
            ..color = Colors.black
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );

        // 텍스트 설정
        final text = '1차 $targetPrice';
        final textStyle = TextStyle(color: Colors.black, fontSize: 12);
        final textSpan = TextSpan(text: text, style: textStyle);
        final textPainter =
            TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout(minWidth: 0, maxWidth: size.width);

        // 텍스트가 들어갈 사각형의 위치와 크기 설정
        final textOffset =
            Offset(start.dx + 6, end.dy - textPainter.height / 2);
        final rect = Rect.fromLTWH(textOffset.dx - 4, textOffset.dy - 1,
            textPainter.width + 8, textPainter.height + 2);

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
      }
      context.canvas.save();
      context.canvas.restore();
    }
  }
}
