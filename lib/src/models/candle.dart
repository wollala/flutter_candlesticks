import 'package:candlesticks/src/utils/helper_functions.dart';

/// Candle model wich holds a single candle data.
/// It contains five required double variables that hold a single candle data: high, low, open, close and volume.
/// It can be instantiated using its default constructor or fromJson named custructor.
class Candle {
  /// DateTime for the candle
  final DateTime date;

  /// The highest price during this candle lifetime
  /// It if always more than low, open and close
  final double high;

  /// The lowest price during this candle lifetime
  /// It if always less than high, open and close
  final double low;

  /// Price at the beginning of the period
  final double open;

  /// Price at the end of the period
  final double close;

  /// Volume is the number of shares of a
  /// security traded during a given period of time.
  final double volume;

  /*
    '1m',
    '3m',
    '5m',
    '15m',
    '30m',
    '1h',
    '2h',
    '4h',
    '6h',
    '8h',
    '12h',
    '1d',
    '3d',
    '1w',
    '1M',
   */
  final String interval;

  bool get isBull => open <= close;

  bool isContain(DateTime time) {
    DateTime start = date;
    DateTime end = date.add(HelperFunctions.getIntervalDuration(interval));
    if (time.isBefore(end) && time.isAfter(start) ||
        time.isAtSameMomentAs(start) ||
        time.isAtSameMomentAs(end)) {
      return true;
    } else {
      return false;
    }
  }

  Candle({
    required this.date,
    required this.high,
    required this.low,
    required this.open,
    required this.close,
    required this.volume,
    required this.interval,
  });

  Candle.fromJson(List<dynamic> json, String interval)
      : date = DateTime.fromMillisecondsSinceEpoch(json[0]),
        high = double.parse(json[2]),
        low = double.parse(json[3]),
        open = double.parse(json[1]),
        close = double.parse(json[4]),
        volume = double.parse(json[5]),
        interval = interval;
}
