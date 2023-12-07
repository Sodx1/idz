// historical_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class HistoricalPage extends StatefulWidget {
  @override
  _HistoricalPageState createState() => _HistoricalPageState();
}

class _HistoricalPageState extends State<HistoricalPage> {
  late DateTime selectedDate = DateTime.now();
  String fromCurrency = 'USD';
  String toCurrency = 'RUB';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Исторические данные'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text('Выбрать дату'),
                ),
                DropdownButton<String>(
                  value: fromCurrency,
                  onChanged: (String? newValue) {
                    setState(() {
                      fromCurrency = newValue!;
                    });
                  },
                  items: <String>['USD', 'EUR', 'GBP', 'JPY', 'RUB', 'AED']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                Text('в'),
                DropdownButton<String>(
                  value: toCurrency,
                  onChanged: (String? newValue) {
                    setState(() {
                      toCurrency = newValue!;
                    });
                  },
                  items: <String>['USD', 'EUR', 'GBP', 'JPY', 'RUB', 'AED']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: fetchData(selectedDate, fromCurrency, toCurrency),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ошибка загрузки данных'));
                } else {
                  return ListView.builder(
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('Дата: ${snapshot.data?['date']}'),
                        subtitle: Text(
                          'Курс $fromCurrency к $toCurrency: ${snapshot.data?['quotes']['$fromCurrency$toCurrency']}',
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchData(DateTime date, String fromCurrency, String toCurrency) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final apiUrl =
        "https://api.apilayer.com/currency_data/historical?date=$formattedDate&from=$fromCurrency&to=$toCurrency";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'apikey': 'JKVhr8Eifnf2iFVCHiWNcYsx3ZZ2re8p'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Не удалось загрузить данные');
      }
    } catch (e) {
      throw Exception('Произошла ошибка: $e');
    }
  }
}
