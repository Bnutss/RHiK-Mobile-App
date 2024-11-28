import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'order_detail_page.dart';
import 'add_order_page.dart';
import 'edit_order_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Order>> _orders;
  String _selectedStatus = 'Все';

  @override
  void initState() {
    super.initState();
    _orders = fetchOrders();
  }

  Future<List<Order>> fetchOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Токен авторизации не найден');
    }

    final response = await http.get(
      Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      List<Order> orders = data.map((json) => Order.fromJson(json)).toList();

      if (_selectedStatus == 'Подтвержден') {
        orders = orders.where((order) => order.isConfirmed).toList();
      } else if (_selectedStatus == 'Отклонен') {
        orders = orders.where((order) => order.isRejected).toList();
      }

      return orders;
    } else {
      throw Exception('Не удалось загрузить заказы: ${response.statusCode}');
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _orders = fetchOrders();
    });
  }

  Future<void> _deleteOrder(int orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/$orderId/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 204) {
      _refreshOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ удален'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при удалении заказа'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showExportDialog(int orderId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите формат'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Отправить в Excel'),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportOrder(orderId, 'excel');
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Отправить в PDF'),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportOrder(orderId, 'pdf');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmOrder(int orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    final response = await http.patch(
      Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/$orderId/confirm/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _refreshOrders();
    } else {
      throw Exception('Не удалось подтвердить заказ');
    }
  }

  Future<void> _rejectOrder(int orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    final response = await http.patch(
      Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/$orderId/reject/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _refreshOrders();
    } else {
      throw Exception('Не удалось отклонить заказ');
    }
  }

  Future<void> _exportOrder(int orderId, String format) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Токен авторизации не найден');
    }

    final url =
        'https://rhik.pythonanywhere.com/sales/api/orders/$orderId/export_to_telegram/?file_type=$format';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заказ успешно экспортирован в формате $format'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при экспорте заказа в формате $format'),
            backgroundColor: Colors.red,
          ),
        );
        throw Exception('Не удалось экспортировать заказ');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Произошла ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey, Colors.red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshOrders,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (String value) {
              setState(() {
                _selectedStatus = value;
                _orders = fetchOrders();
              });
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Все',
                  child: ListTile(
                    leading: Icon(Icons.all_inclusive, color: Colors.black),
                    title: Text('Все', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Подтвержден',
                  child: ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Подтвержден', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Отклонен',
                  child: ListTile(
                    leading: Icon(Icons.cancel, color: Colors.red),
                    title: Text('Отклонен', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<Order>>(
          future: _orders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final orders = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _refreshOrders,
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final warrantyDaysLeft = order.warrantyDaysLeft != null
                        ? '${order.warrantyDaysLeft} дней'
                        : 'Нет гарантии';
                    final status = order.isConfirmed
                        ? 'Подтвержден'
                        : order.isRejected
                        ? 'Отклонен'
                        : 'Не обработан';

                    return Dismissible(
                      key: ValueKey(order.id),
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.next_plan_outlined, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.horizontal,
                      onDismissed: (direction) {
                        if (direction == DismissDirection.startToEnd) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Выберите действие'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit, color: Colors.green),
                                      title: const Text('Редактировать'),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditOrderPage(orderId: order.id),
                                          ),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.send, color: Colors.blue),
                                      title: const Text('Отправить по телеграмму'),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        _showExportDialog(order.id);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        } else if (direction == DismissDirection.endToStart) {
                          _deleteOrder(order.id);
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              order.isConfirmed ? Icons.done :
                              order.isRejected ? Icons.close : Icons.pending,
                              color: order.isConfirmed ? Colors.green :
                              order.isRejected ? Colors.red : Colors.orange,
                              size: 20,
                            ),
                          ),
                          title: Text(order.client,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, color: Colors.black54, size: 14),
                                  const SizedBox(width: 2),
                                  Text('НДС: ${order.vat}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.monetization_on, color: Colors.black54, size: 14),
                                  const SizedBox(width: 2),
                                  Text('Доп. расходы: ${order.additionalExpenses}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.shield, color: Colors.black54, size: 14),
                                  const SizedBox(width: 2),
                                  Text('Гарантия: $warrantyDaysLeft ', style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.black54, size: 14),
                                  const SizedBox(width: 2),
                                  Text('Статус: $status', style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.money_off, color: Colors.black54, size: 14),
                                  const SizedBox(width: 2),
                                  Text('Сумма расходов: ${order.additionalExpensesAmount?.toStringAsFixed(2)}', style: const TextStyle( fontSize: 11)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.money_off, color: Colors.black54, size: 14),
                                  const SizedBox(width: 2),
                                  Text('Сумма без НДС: ${order.totalPriceWithoutVat}', style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, color: Colors.black54, size: 14),
                                  const SizedBox(width: 2),
                                  Text('Общая сумма: ${order.totalPriceWithVat}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          trailing: Padding(
                            padding: const EdgeInsets.only(left: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!order.isConfirmed && !order.isRejected)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline, size: 20),
                                    color: Colors.green,
                                    onPressed: () => _confirmOrder(order.id),
                                  ),
                                if (!order.isConfirmed && !order.isRejected)
                                  IconButton(
                                    icon: const Icon(Icons.cancel_outlined, size: 20),
                                    color: Colors.red,
                                    onPressed: () => _rejectOrder(order.id),
                                  ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailPage(orderId: order.id),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            } else {
              return const Center(child: Text('Нет доступных данных'));
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddOrderPage()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class Order {
  final int id;
  final String client;
  final double vat;
  final double? additionalExpenses;
  final bool isConfirmed;
  final bool isRejected;
  final int? warrantyDaysLeft;
  final double? totalPriceWithoutVat;
  final double? totalPriceWithVat;

  Order({
    required this.id,
    required this.client,
    required this.vat,
    this.additionalExpenses,
    required this.isConfirmed,
    required this.isRejected,
    this.warrantyDaysLeft,
    this.totalPriceWithoutVat,
    this.totalPriceWithVat,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      client: json['client'],
      vat: json['vat'] != null ? double.tryParse(json['vat'].toString()) ?? 0.0 : 0.0,
      additionalExpenses: json['additional_expenses'] != null ? double.tryParse(json['additional_expenses'].toString()) ?? 0.0 : 0.0,  // Обновлено
      isConfirmed: json['is_confirmed'],
      isRejected: json['is_rejected'],
      warrantyDaysLeft: json['warranty_days_left'],
      totalPriceWithoutVat: json['total_price_without_vat'] != null ? double.tryParse(json['total_price_without_vat'].toString()) ?? 0.0 : 0.0,  // Обновлено
      totalPriceWithVat: json['total_price_with_vat'] != null ? double.tryParse(json['total_price_with_vat'].toString()) ?? 0.0 : 0.0,  // Обновлено
    );
  }

  double? get additionalExpensesAmount {
    if (additionalExpenses != null && totalPriceWithoutVat != null) {
      return totalPriceWithoutVat! * (additionalExpenses! / 100);
    }
    return null;
  }
}
