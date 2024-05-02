import 'package:candlesticks/src/models/candle.dart';
import 'package:candlesticks/src/utils/helper_functions.dart';
import 'package:flutter/material.dart';

class CandleInfoText extends StatelessWidget {
  const CandleInfoText({
    Key? key,
    required this.candle,
    required this.bullColor,
    required this.bearColor,
    required this.backgroundColor,
    required this.defaultStyle,
  }) : super(key: key);

  final Candle candle;
  final Color bullColor;
  final Color bearColor;
  final Color backgroundColor;
  final TextStyle defaultStyle;

  String numberFormat(int value) {
    return "${value < 10 ? 0 : ""}$value";
  }

  String dateFormatter(DateTime date) {
    return "${date.year}-${numberFormat(date.month)}-${numberFormat(date.day)} ${numberFormat(date.hour)}:${numberFormat(date.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: RichText(
        text: TextSpan(
          text: dateFormatter(candle.date),
          style: defaultStyle,
          children: <TextSpan>[
            TextSpan(text: " 시: "),
            TextSpan(
              text: HelperFunctions.priceToString(candle.open),
              style: TextStyle(
                color: candle.isBull ? bullColor : bearColor,
              ),
            ),
            TextSpan(text: " 고: "),
            TextSpan(
              text: HelperFunctions.priceToString(candle.high),
              style: TextStyle(
                color: candle.isBull ? bullColor : bearColor,
              ),
            ),
            TextSpan(text: " 저: "),
            TextSpan(
              text: HelperFunctions.priceToString(candle.low),
              style: TextStyle(
                color: candle.isBull ? bullColor : bearColor,
              ),
            ),
            TextSpan(text: " 종: "),
            TextSpan(
              text: HelperFunctions.priceToString(candle.close),
              style: TextStyle(
                color: candle.isBull ? bullColor : bearColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
