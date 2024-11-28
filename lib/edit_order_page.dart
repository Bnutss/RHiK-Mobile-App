import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditOrderPage extends StatefulWidget {
  final int orderId;

  const EditOrderPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _EditOrderPageState createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientController = TextEditingController();
  final _vatController = TextEditingController();
  final _additionalExpensesController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final response = await http.get(
        Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/${widget.orderId}/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> orderData = json.decode(response.body);

        setState(() {
          _clientController.text = orderData['client'] ?? '';
          _vatController.text = (orderData['vat'] ?? 0).toString();
          _additionalExpensesController.text = (orderData['additional_expenses'] ?? 0).toString();
          _isLoading = false;
        });
      } else {
        _showError('Ошибка загрузки данных заказа: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Не удалось загрузить заказ: $e');
    }
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.put(
          Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/${widget.orderId}/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'client': _clientController.text,
            'vat': double.tryParse(_vatController.text) ?? 0.0,
            'additional_expenses': double.tryParse(_additionalExpensesController.text) ?? 0.0,
          }),
        );

        if (response.statusCode == 200) {
          _showSuccess('Заказ успешно обновлен!');
          Navigator.pop(context, true);
        } else {
          _showError('Ошибка обновления заказа: ${response.statusCode}');
        }
      } catch (e) {
        _showError('Не удалось обновить заказ: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Редактировать заказ',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
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
                  icon: const Icon(Icons.save, color: Colors.black),
                  label: const Text(
                    'Сохранить изменения',
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
