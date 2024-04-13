import 'dart:math';

import 'package:candlesticks/src/constant/view_constants.dart';

class HelperFunctions {
  static double log10(num x) => log(x) / ln10;

  static double getRoof(double number) {
    if (number == 0) {
      return 1;
    }
    int log = log10(number).floor();
    return (number ~/ pow(10, log) + 1) * pow(10, log).toDouble();
  }

  static String addMetricPrefix(double price) {
    if (price < 1) price = 1;
    int log = log10(price).floor();
    if (log > 9)
      return "${price ~/ 1000000000}B";
    else if (log > 6)
      return "${price ~/ 1000000}M";
    else if (log > 3)
      return "${price ~/ 1000}K";
    else
      return "${price.toStringAsFixed(0)}";
  }

  static String priceToString(double price) {
    return price.abs() > 1000
        ? price.toStringAsFixed(2)
        : price.abs() > 100
            ? price.toStringAsFixed(3)
            : price.abs() > 10
                ? price.toStringAsFixed(4)
                : price.abs() > 1
                    ? price.toStringAsFixed(5)
                    : price.toStringAsFixed(7);
  }

  static double calculatePriceScale(double height, double high, double low) {
    int minTiles = (height / MIN_PRICETILE_HEIGHT).floor();
    minTiles = max(2, minTiles);
    double sizeRange = high - low;
    assert(sizeRange != 0,
        "highest highs and lowest lows of visible candles are equal.");
    double minStepSize = sizeRange / minTiles;
    double base =
        pow(10, HelperFunctions.log10(minStepSize).floor()).toDouble();

    if (2 * base > minStepSize) return 2 * base;
    if (5 * base > minStepSize) return 5 * base;
    return 10 * base;
  }

  static Duration getIntervalDuration(String interval) {
    switch (interval) {
      case '1m':
        return Duration(minutes: 1);
      case '3m':
        return Duration(minutes: 3);
      case '5m':
        return Duration(minutes: 5);
      case '15m':
        return Duration(minutes: 15);
      case '30m':
        return Duration(minutes: 30);
      case '1h':
        return Duration(hours: 1);
      case '2h':
        return Duration(hours: 2);
      case '4h':
        return Duration(hours: 4);
      case '6h':
        return Duration(hours: 6);
      case '8h':
        return Duration(hours: 8);
      case '12h':
        return Duration(hours: 12);
      case '1d':
        return Duration(days: 1);
      case '3d':
        return Duration(days: 3);
      case '1w':
        return Duration(days: 7);
      case '1M':
        return Duration(days: 30);
      default:
        return Duration(minutes: 1);
    }
  }
}
