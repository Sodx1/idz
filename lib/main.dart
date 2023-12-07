import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class ConversionHistory {
  final int id;
  final DateTime timestamp;
  final double amount;
  final String fromCurrency;
  final String toCurrency;
  final double result;

  ConversionHistory({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.result,
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Конвектор валют',
      home: CurrencyConverter(),
    );
  }
}

class CurrencyConverter extends StatefulWidget {
  @override
  _CurrencyConverterState createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  double amount = 1.0;
  String fromCurrency = 'USD';
  String toCurrency = 'RUB';
  double result = 0.0;

  List<ConversionHistory> conversionHistory = [];

  late Database _database;

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  Future<void> initDatabase() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = Path.join(directory.path, 'currency_converter.db');

    _database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
        CREATE TABLE IF NOT EXISTS conversion_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp TEXT,
          amount REAL,
          from_currency TEXT,
          to_currency TEXT,
          result REAL
        )
      ''');
        });

    loadConversionHistory();
  }

  Future<void> loadConversionHistory() async {
    final List<Map<String, dynamic>> historyList =
    await _database.query('conversion_history');

    setState(() {
      conversionHistory = historyList
          .map((history) => ConversionHistory(
        id: history['id'],
        timestamp: DateTime.parse(history['timestamp']),
        amount: history['amount'],
        fromCurrency: history['from_currency'],
        toCurrency: history['to_currency'],
        result: history['result'],
      ))
          .toList();
    });
  }

  Future<void> saveConversionHistory() async {
    for (final history in conversionHistory) {
      await _database.insert('conversion_history', {
        'timestamp': history.timestamp.toIso8601String(),
        'amount': history.amount,
        'from_currency': history.fromCurrency,
        'to_currency': history.toCurrency,
        'result': history.result,
      });
    }
  }

  // Метод для удаления всех записей из истории
  Future<void> clearConversionHistory() async {
    await _database.delete('conversion_history');
    loadConversionHistory();
  }

  void convertCurrency() async {
    if (fromCurrency == toCurrency) {
      _showErrorSnackBar('Выберите разные валюты для конвертации.');
      return;
    }

    String apiUrl =
        'https://api.apilayer.com/currency_data/convert?to=$toCurrency&from=$fromCurrency&amount=$amount';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'apikey': 'JKVhr8Eifnf2iFVCHiWNcYsx3ZZ2re8p'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            result = data['result'];

            // Добавление записи в историю
            conversionHistory.add(ConversionHistory(
              id: 0,
              timestamp: DateTime.now(),
              amount: amount,
              fromCurrency: fromCurrency,
              toCurrency: toCurrency,
              result: result,
            ));

            // Сохранение истории
            saveConversionHistory();
          });
        } else {
          _showErrorSnackBar(
              'Ошибка конвертации валют. Ошибка: ${data['error']}');
        }
      } else {
        _showErrorSnackBar(
            'Ошибка загрузки данных. Код ошибки: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Конвектор валют'),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        amount = double.parse(value);
                      });
                    },
                    decoration: InputDecoration(labelText: 'Сумма'),
                  ),
                ),
                SizedBox(width: 20),
                Flexible(
                  child: DropdownButton<String>(
                    value: fromCurrency,
                    onChanged: (String? newValue) {
                      setState(() {
                        fromCurrency = newValue!;
                      });
                    },
                    items: <String>['USD', 'EUR', 'GBP', 'JPY', 'RUB',"AED","AFN"]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                Icon(Icons.arrow_forward),
                Flexible(
                  child: DropdownButton<String>(
                    value: toCurrency,
                    onChanged: (String? newValue) {
                      setState(() {
                        toCurrency = newValue!;
                      });
                    },
                    items: <String>['USD', 'EUR', 'GBP', 'JPY', 'RUB',"AED","AFN"]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: convertCurrency,
              child: Text('Конвектировать'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: clearConversionHistory,
              child: Text('Очистить историю'),
            ),
            SizedBox(height: 20),
            Text(
              'Результат: $result $toCurrency',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: conversionHistory.length,
                itemBuilder: (context, index) {
                  final historyItem = conversionHistory[index];
                  return ListTile(
                    title: Text(
                      'Конвектированно ${historyItem.amount} ${historyItem.fromCurrency} в ${historyItem.result} ${historyItem.toCurrency}',
                    ),
                    subtitle: Text(
                      'Время: ${DateFormat.yMd().add_Hms().format(historyItem.timestamp)}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        // Удаление записи из базы данных
                        _database.delete('conversion_history',
                            where: 'id = ?', whereArgs: [historyItem.id]);
                        loadConversionHistory();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}