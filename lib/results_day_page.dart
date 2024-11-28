import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ResultsDayPage extends StatefulWidget {
  @override
  _ResultsDayPageState createState() => _ResultsDayPageState();
}

class _ResultsDayPageState extends State<ResultsDayPage> {
  List orders = [];
  double totalSum = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    fetchConfirmedOrders();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null && picked.start != null && picked.end != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      fetchConfirmedOrders();
    }
  }

  Future<void> fetchConfirmedOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null) {
      final String? startDate = _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null;
      final String? endDate = _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null;

      final queryParameters = {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };
      final uri = Uri.http(
        '127.0.0.1:8000',
        '/sales/api/confirmed-orders/',
        queryParameters,
      );

      try {
        final response = await http.get(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            orders = data['orders'];
            totalSum = data['total_sum'];
          });
        } else {
          _showError('Ошибка получения заказов: ${response.statusCode}');
        }
      } catch (e) {
        _showError('Ошибка соединения с сервером');
      }
    } else {
      _showError('Токен авторизации не найден');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Text(message),
        ],
      )),
    );
  }

  Future<void> _refreshOrders() async {
    await fetchConfirmedOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Итоги дня'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey, Colors.red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey, Colors.red],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: RefreshIndicator(
              onRefresh: _refreshOrders,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        DateTime orderDate = DateTime.parse(order['created_at']);
                        String formattedDate = DateFormat('dd.MM.yyyy').format(orderDate);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: Icon(Icons.shopping_bag, color: Colors.blue),
                            title: Row(
                              children: [
                                Icon(Icons.person, color: Colors.purple),
                                SizedBox(width: 8),
                                Text('Клиент: ${order['client']}'),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.attach_money, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Стоимость: ${order['total_price_with_vat']}'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.date_range, color: Colors.teal),
                                    SizedBox(width: 8),
                                    Text('Дата заказа: $formattedDate'),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.blueGrey.shade700,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Общая сумма:',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.yellow),
                      SizedBox(width: 8),
                      Text(
                        '$totalSum',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
