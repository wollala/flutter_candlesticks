import 'dart:convert';

import 'package:candlesticks/candlesticks.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import './candle_ticker_model.dart';
import './repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BinanceRepository repository = BinanceRepository();

  List<Candle> candles = [];
  WebSocketChannel? _channel;
  bool themeIsDark = false;
  String currentInterval = "1m";
  final intervals = [
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
  ];
  List<String> symbols = [];
  String currentSymbol = "";
  List<Indicator> indicators = [
    BollingerBandsIndicator(
      length: 20,
      stdDev: 2,
      upperColor: const Color(0xFF2962FF),
      basisColor: const Color(0xFFFF6D00),
      lowerColor: const Color(0xFF2962FF),
    ),
    WeightedMovingAverageIndicator(
      length: 100,
      color: Colors.green.shade600,
    ),
  ];

  List<LineDrawing> lines = [
    LineDrawing(
        leftX: DateTime(2024, 4, 13, 20, 00, 00),
        rightX: DateTime(2024, 4, 13, 21, 00, 00),
        leftY: 0.0485501,
        rightY: 0.0485501,
        lineRange: LineRange.leftOpen,
        lineStyle: LineStyle.solid,
        lineWidth: 0.5,
        text: "1차"),
    LineDrawing(
        leftX: DateTime(2024, 4, 14, 1, 00, 00),
        rightX: DateTime(2024, 4, 14, 2, 00, 00),
        leftY: 0.0481701,
        rightY: 0.0481701,
        lineRange: LineRange.rightOpen,
        lineStyle: LineStyle.solid,
        lineWidth: 0.5,
        text: "2차"),
  ];

  void updateDrawing(List<LineDrawing> newDrawing) {
    setState(() {
      lines = newDrawing;
    });
  }

  @override
  void initState() {
    fetchSymbols().then((value) {
      symbols = value;
      if (symbols.isNotEmpty) fetchCandles(symbols[0], currentInterval);
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_channel != null) _channel!.sink.close();
    super.dispose();
  }

  Future<List<String>> fetchSymbols() async {
    try {
      // load candles info
      final data = await repository.fetchSymbols();
      return data;
    } catch (e) {
      // handle error
      return [];
    }
  }

  Future<void> fetchCandles(String symbol, String interval) async {
    // close current channel if exists
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    // clear last candle list
    setState(() {
      candles = [];
      currentInterval = interval;
    });

    try {
      // load candles info
      final data =
          await repository.fetchCandles(symbol: symbol, interval: interval);
      // connect to binance stream
      _channel =
          repository.establishConnection(symbol.toLowerCase(), currentInterval);
      // update candles
      setState(() {
        candles = data;
        currentInterval = interval;
        currentSymbol = symbol;
      });
    } catch (e) {
      // handle error
      return;
    }
  }

  void updateCandlesFromSnapshot(AsyncSnapshot<Object?> snapshot) {
    if (candles.isEmpty) return;
    if (snapshot.data != null) {
      final map = jsonDecode(snapshot.data as String) as Map<String, dynamic>;
      if (map.containsKey("k") == true) {
        final candleTicker = CandleTickerModel.fromJson(map);

        // cehck if incoming candle is an update on current last candle, or a new one
        if (candles[0].date == candleTicker.candle.date &&
            candles[0].open == candleTicker.candle.open) {
          // update last candle
          candles[0] = candleTicker.candle;
        }
        // check if incoming new candle is next candle so the difrence
        // between times must be the same as last existing 2 candles
        else if (candleTicker.candle.date.difference(candles[0].date) ==
            candles[0].date.difference(candles[1].date)) {
          // add new candle to list
          candles.insert(0, candleTicker.candle);
        }
      }
    }
  }

  Future<void> loadMoreCandles() async {
    try {
      // load candles info
      final data = await repository.fetchCandles(
          symbol: currentSymbol,
          interval: currentInterval,
          endTime: candles.last.date.millisecondsSinceEpoch);
      candles.removeLast();
      setState(() {
        candles.addAll(data);
      });
    } catch (e) {
      // handle error
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeIsDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Binance Candles"),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  themeIsDark = !themeIsDark;
                });
              },
              icon: Icon(
                themeIsDark
                    ? Icons.wb_sunny_sharp
                    : Icons.nightlight_round_outlined,
              ),
            )
          ],
        ),
        body: Center(
          child: StreamBuilder(
            stream: _channel == null ? null : _channel!.stream,
            builder: (context, snapshot) {
              updateCandlesFromSnapshot(snapshot);
              return Candlesticks(
                key: Key(currentSymbol + currentInterval),
                indicators: indicators,
                candles: candles,
                onLoadMoreCandles: loadMoreCandles,
                onRemoveIndicator: (String indicator) {
                  setState(() {
                    indicators = [...indicators];
                    indicators
                        .removeWhere((element) => element.name == indicator);
                  });
                },
                drawing: lines,
                actions: [
                  ToolBarAction(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Center(
                            child: Container(
                              width: 198,
                              color: Theme.of(context).colorScheme.background,
                              child: Wrap(
                                children: intervals
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: SizedBox(
                                            width: 60,
                                            height: 32,
                                            child: RawMaterialButton(
                                              elevation: 0,
                                              fillColor:
                                                  const Color(0xFF494537),
                                              onPressed: () {
                                                fetchCandles(currentSymbol, e);
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                e,
                                                style: const TextStyle(
                                                  color: Color(0xFFF0B90A),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Text(
                      currentInterval,
                    ),
                  ),
                  ToolBarAction(
                    width: 100,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return SymbolsSearchModal(
                            symbols: symbols,
                            onSelect: (value) {
                              fetchCandles(value, currentInterval);
                            },
                          );
                        },
                      );
                    },
                    child: Text(
                      currentSymbol,
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class SymbolsSearchModal extends StatefulWidget {
  const SymbolsSearchModal({
    Key? key,
    required this.onSelect,
    required this.symbols,
  }) : super(key: key);

  final Function(String symbol) onSelect;
  final List<String> symbols;

  @override
  State<SymbolsSearchModal> createState() => _SymbolSearchModalState();
}

class _SymbolSearchModalState extends State<SymbolsSearchModal> {
  String symbolSearch = "";
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          height: MediaQuery.of(context).size.height * 0.75,
          color: Theme.of(context).colorScheme.background.withOpacity(0.5),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(
                  onChanged: (value) {
                    setState(() {
                      symbolSearch = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  children: widget.symbols
                      .where((element) => element
                          .toLowerCase()
                          .contains(symbolSearch.toLowerCase()))
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: SizedBox(
                              width: 50,
                              height: 30,
                              child: RawMaterialButton(
                                elevation: 0,
                                fillColor: const Color(0xFF494537),
                                onPressed: () {
                                  widget.onSelect(e);
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    color: Color(0xFFF0B90A),
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({Key? key, required this.onChanged}) : super(key: key);
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      cursorColor: const Color(0xFF494537),
      decoration: const InputDecoration(
        prefixIcon: Icon(
          Icons.search,
          color: Color(0xFF494537),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(width: 3, color: Color(0xFF494537)), //<-- SEE HER
        ),
        border: OutlineInputBorder(
          borderSide:
              BorderSide(width: 3, color: Color(0xFF494537)), //<-- SEE HER
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(width: 3, color: Color(0xFF494537)), //<-- SEE HER
        ),
      ),
      onChanged: onChanged,
    );
  }
}
