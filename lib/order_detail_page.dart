import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<OrderDetails> _orderDetails;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _orderDetails = fetchOrderDetails(widget.orderId);
  }

  Future<OrderDetails> fetchOrderDetails(int orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Токен авторизации не найден');
    }

    final response = await http.get(
      Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/$orderId/'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return OrderDetails.fromJson(jsonResponse);
    } else {
      throw Exception('Не удалось загрузить данные: ${response.statusCode}');
    }
  }

  Future<void> _addProductToOrder(String name, int quantity, double price, File? image) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Токен авторизации не найден');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/${widget.orderId}/products/'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name
      ..fields['quantity'] = quantity.toString()
      ..fields['price'] = price.toString();

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', image.path));
    }

    final response = await request.send();

    if (response.statusCode == 201) {
      setState(() {
        _orderDetails = fetchOrderDetails(widget.orderId);
      });
      _showSnackBar('Товар успешно добавлен', Colors.green);
    } else {
      _showSnackBar('Ошибка добавления товара. Код: ${response.statusCode}', Colors.red);
    }
  }

  Future<void> _showAddProductDialog(BuildContext context) async {
    final _nameController = TextEditingController();
    final _quantityController = TextEditingController();
    final _priceController = TextEditingController();
    File? dialogImage;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Добавить товар'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Название товара'),
                    ),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Количество'),
                    ),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Цена за единицу'),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                        if (pickedFile != null) {
                          setState(() {
                            dialogImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: dialogImage == null
                            ? const Icon(Icons.camera_alt, color: Colors.grey, size: 40)
                            : Image.file(dialogImage!, fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      child: const Text('Загрузить фото'),
                      onPressed: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            dialogImage = File(pickedFile.path);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Отмена'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Добавить'),
                  onPressed: () {
                    final name = _nameController.text;
                    final quantity = int.tryParse(_quantityController.text) ?? 0;
                    final price = double.tryParse(_priceController.text) ?? 0.0;

                    if (name.isNotEmpty && quantity > 0 && price > 0) {
                      _addProductToOrder(name, quantity, price, dialogImage);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editProductInOrder(int productId, String name, int quantity, double price, File? image) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Токен авторизации не найден');
    }

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/${widget.orderId}/products/$productId/'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = name
      ..fields['quantity'] = quantity.toString()
      ..fields['price'] = price.toString();

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', image.path));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      setState(() {
        _orderDetails = fetchOrderDetails(widget.orderId);
      });
      _showSnackBar('Товар успешно отредактирован', Colors.green);
    } else {
      _showSnackBar('Ошибка редактирования товара. Код: ${response.statusCode}', Colors.red);
    }
  }

  Future<void> _deleteProductFromOrder(int productId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Токен авторизации не найден');
    }

    final response = await http.delete(
      Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/${widget.orderId}/products/$productId/'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 204) {
      setState(() {
        _orderDetails = fetchOrderDetails(widget.orderId);
      });
      _showSnackBar('Товар успешно удален', Colors.green);
    } else {
      _showSnackBar('Ошибка удаления товара. Код: ${response.statusCode}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары заказа', style: TextStyle(color: Colors.white)),
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              await _showAddProductDialog(context);
            },
          ),
        ],
      ),
      body: FutureBuilder<OrderDetails>(
        future: _orderDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final orderDetails = snapshot.data!;
            final products = orderDetails.products;

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Количество: ${product.quantity}'),
                              Text('Цена за единицу: ${product.price}'),
                              Text('Общая цена: ${product.totalPrice}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showEditProductDialog(context, product);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _confirmDeleteProduct(product.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.money_off, color: Colors.green, size: 30),
                              const SizedBox(width: 10),
                              Text(
                                'Сумма без НДС: ${orderDetails.totalPriceWithoutVat.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.attach_money, color: Colors.blue, size: 30),
                              const SizedBox(width: 10),
                              Text(
                                'Сумма с НДС: ${orderDetails.totalPriceWithVat.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('Нет доступных данных'));
          }
        },
      ),
    );
  }

  Future<void> _showEditProductDialog(BuildContext context, OrderProduct product) async {
    final _nameController = TextEditingController(text: product.name);
    final _quantityController = TextEditingController(text: product.quantity.toString());
    final _priceController = TextEditingController(text: product.price.toString());
    File? dialogImage;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Редактировать товар'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Название товара'),
                    ),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Количество'),
                    ),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Цена за единицу'),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.camera);
                        if (pickedFile != null) {
                          setState(() {
                            dialogImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: dialogImage == null
                            ? const Icon(Icons.camera_alt, color: Colors.grey, size: 40)
                            : Image.file(dialogImage!, fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      child: const Text('Загрузить фото'),
                      onPressed: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            dialogImage = File(pickedFile.path);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Отмена'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Сохранить'),
                  onPressed: () {
                    final name = _nameController.text;
                    final quantity = int.tryParse(_quantityController.text) ?? 0;
                    final price = double.tryParse(_priceController.text) ?? 0.0;

                    if (name.isNotEmpty && quantity > 0 && price > 0) {
                      _editProductInOrder(product.id, name, quantity, price, dialogImage);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteProduct(int productId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение удаления'),
          content: const Text('Вы уверены, что хотите удалить этот товар?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Удалить'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProductFromOrder(productId);
              },
            ),
          ],
        );
      },
    );
  }
}

class OrderProduct {
  final int id;
  final String name;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderProduct({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      id: json['id'],
      name: json['name'] ?? 'Неизвестный продукт',
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
    );
  }
}

class OrderDetails {
  final String client;
  final double vat;
  final List<OrderProduct> products;
  final double totalPriceWithoutVat;
  final double totalPriceWithVat;

  OrderDetails({
    required this.client,
    required this.vat,
    required this.products,
    required this.totalPriceWithoutVat,
    required this.totalPriceWithVat,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    var productsList = (json['products'] as List)
        .map((productJson) => OrderProduct.fromJson(productJson))
        .toList();

    return OrderDetails(
      client: json['client'],
      vat: double.tryParse(json['vat'].toString()) ?? 0.0,
      products: productsList,
      totalPriceWithoutVat: double.tryParse(json['total_price_without_vat'].toString()) ?? 0.0,
      totalPriceWithVat: double.tryParse(json['total_price_with_vat'].toString()) ?? 0.0,
    );
  }
}
