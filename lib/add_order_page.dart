import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'order_detail_page.dart';

class AddOrderPage extends StatefulWidget {
  final int? orderId;

  const AddOrderPage({Key? key, this.orderId}) : super(key: key);

  @override
  _AddOrderPageState createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _vatController = TextEditingController();
  final _additionalExpensesController = TextEditingController();

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Токен не найден'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'client': _clientController.text,
          'vat': _vatController.text.isEmpty ? null : double.tryParse(_vatController.text),
          'additional_expenses': _additionalExpensesController.text.isEmpty ? null : double.tryParse(_additionalExpensesController.text),
          'is_confirmed': false,
        }),
      );

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final int newOrderId = jsonResponse['id'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(orderId: newOrderId),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заказ успешно создан'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания заказа: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Добавить заказ',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.grey],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red, Colors.grey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _clientController,
                  decoration: InputDecoration(
                    labelText: 'Клиент',
                    prefixIcon: const Icon(Icons.person, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите имя клиента';
                    }
                    return null;
                  },
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _vatController,
                  decoration: InputDecoration(
                    labelText: 'НДС (%)',
                    prefixIcon: const Icon(Icons.money, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _additionalExpensesController,
                  decoration: InputDecoration(
                    labelText: 'Прочие расходы (%)',
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _submitOrder,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                  label: const Text(
                    'Создать заказ',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
