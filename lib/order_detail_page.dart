import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage>
    with SingleTickerProviderStateMixin {
  late Future<OrderDetails> _orderDetails;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _orderDetails = fetchOrderDetails(widget.orderId);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<OrderDetails> fetchOrderDetails(int orderId) async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Токен авторизации не найден');
    }

    try {
      final response = await http.get(
        Uri.parse('https://rhik.pythonanywhere.com/sales/api/orders/$orderId/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _isLoading = false;
        });
        return OrderDetails.fromJson(jsonResponse);
      } else {
        setState(() {
          _isLoading = false;
        });
        throw Exception('Не удалось загрузить данные: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Ошибка: $e');
    }
  }

  Future<void> _addProductToOrder(
      String name, int quantity, double price, File? image) async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Токен авторизации не найден');
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://rhik.pythonanywhere.com/sales/api/orders/${widget.orderId}/products/'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['name'] = name
        ..fields['quantity'] = quantity.toString()
        ..fields['price'] = price.toString();

      if (image != null) {
        request.files
            .add(await http.MultipartFile.fromPath('photo', image.path));
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        setState(() {
          _orderDetails = fetchOrderDetails(widget.orderId);
        });
        _showSnackBar('Товар успешно добавлен', false);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
            'Ошибка добавления товара. Код: ${response.statusCode}', true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Ошибка: $e', true);
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
              backgroundColor: Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Добавить товар',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Название товара',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFFFF4081)),
                        ),
                        prefixIcon: Icon(Icons.shopping_bag_outlined,
                            color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Количество',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFFFF4081)),
                        ),
                        prefixIcon: Icon(Icons.format_list_numbered,
                            color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Цена за единицу',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFFFF4081)),
                        ),
                        prefixIcon:
                            Icon(Icons.attach_money, color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Фото товара',
                      style: GoogleFonts.montserrat(
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile =
                            await _picker.pickImage(source: ImageSource.camera);
                        if (pickedFile != null) {
                          setState(() {
                            dialogImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white30,
                            width: 1,
                          ),
                        ),
                        child: dialogImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white70,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Сделать фото',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  dialogImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: Icon(Icons.photo_library_outlined),
                      label: Text('Выбрать из галереи'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final pickedFile = await _picker.pickImage(
                            source: ImageSource.gallery);
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
                  child: Text(
                    'Отмена',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text(
                    'Добавить',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF4081),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final name = _nameController.text;
                    final quantity =
                        int.tryParse(_quantityController.text) ?? 0;
                    final price = double.tryParse(_priceController.text) ?? 0.0;

                    if (name.isNotEmpty && quantity > 0 && price > 0) {
                      _addProductToOrder(name, quantity, price, dialogImage);
                      Navigator.of(context).pop();
                    } else {
                      _showSnackBar(
                          'Пожалуйста, заполните все поля корректно', true);
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

  Future<void> _editProductInOrder(int productId, String name, int quantity,
      double price, File? image) async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Токен авторизации не найден');
    }

    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            'https://rhik.pythonanywhere.com/sales/api/orders/${widget.orderId}/products/$productId/'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['name'] = name
        ..fields['quantity'] = quantity.toString()
        ..fields['price'] = price.toString();

      if (image != null) {
        request.files
            .add(await http.MultipartFile.fromPath('photo', image.path));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          _orderDetails = fetchOrderDetails(widget.orderId);
        });
        _showSnackBar('Товар успешно отредактирован', false);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
            'Ошибка редактирования товара. Код: ${response.statusCode}', true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Ошибка: $e', true);
    }
  }

  Future<void> _deleteProductFromOrder(int productId) async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Токен авторизации не найден');
    }

    try {
      final response = await http.delete(
        Uri.parse(
            'https://rhik.pythonanywhere.com/sales/api/orders/${widget.orderId}/products/$productId/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          _orderDetails = fetchOrderDetails(widget.orderId);
        });
        _showSnackBar('Товар успешно удален', false);
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
            'Ошибка удаления товара. Код: ${response.statusCode}', true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Ошибка: $e', true);
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: isError ? Colors.red.shade700 : Color(0xFF303F9F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        action: isError
            ? null
            : SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Детали заказа',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Темно-синий
              Color(0xFF3949AB), // Индиго
              Color(0xFF303F9F), // Синий
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: _isLoading
                ? _buildLoadingShimmer()
                : FutureBuilder<OrderDetails>(
                    future: _orderDetails,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingShimmer();
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade300,
                                  size: 60,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Ошибка: ${snapshot.error}',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _orderDetails =
                                          fetchOrderDetails(widget.orderId);
                                    });
                                  },
                                  icon: Icon(Icons.refresh),
                                  label: Text('Повторить'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFF4081),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (snapshot.hasData) {
                        final orderDetails = snapshot.data!;
                        final products = orderDetails.products;

                        return Column(
                          children: [
                            // Информация о клиенте
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            Color(0xFFFF4081).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_outline,
                                        color: Color(0xFFFF4081),
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Клиент:',
                                          style: GoogleFonts.montserrat(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          orderDetails.client,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Заголовок списка товаров
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Товары заказа (${products.length})',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      await _showAddProductDialog(context);
                                    },
                                    tooltip: 'Добавить товар',
                                  ),
                                ],
                              ),
                            ),

                            // Список товаров
                            Expanded(
                              child: products.isEmpty
                                  ? _buildEmptyProductsList()
                                  : ListView.builder(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: products.length,
                                      itemBuilder: (context, index) {
                                        final product = products[index];
                                        return Animate(
                                          effects: [
                                            FadeEffect(
                                                duration: 300.ms,
                                                delay: (50 * index).ms)
                                          ],
                                          child: _buildProductCard(
                                              product, context),
                                        );
                                      },
                                    ),
                            ),

                            // Итоговая информация
                            _buildOrderSummary(orderDetails),
                          ],
                        );
                      } else {
                        return Center(
                          child: Text(
                            'Нет доступных данных',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _showAddProductDialog(context);
        },
        backgroundColor: Color(0xFFFF4081),
        child: const Icon(Icons.add),
        tooltip: 'Добавить товар',
      ),
    );
  }

  Widget _buildProductCard(OrderProduct product, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            title: Text(
              product.name,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  _buildProductInfoChip(
                    Icons.format_list_numbered,
                    'Кол-во: ${product.quantity}',
                    Colors.amber,
                  ),
                  SizedBox(width: 8),
                  _buildProductInfoChip(
                    Icons.attach_money,
                    'Цена: ${product.price}',
                    Colors.green,
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () {
                    _showEditProductDialog(context, product);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade300,
                    size: 20,
                  ),
                  onPressed: () {
                    _confirmDeleteProduct(product.id);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFF4081).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_checkout,
                    color: Color(0xFFFF4081),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Общая сумма: ${product.totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(OrderDetails orderDetails) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A237E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                icon: Icons.money_off,
                title: 'Без НДС',
                value: orderDetails.totalPriceWithoutVat.toStringAsFixed(2),
                color: Colors.blue,
              ),
              _buildSummaryItem(
                icon: Icons.attach_money,
                title: 'С НДС (${orderDetails.vat}%)',
                value: orderDetails.totalPriceWithVat.toStringAsFixed(2),
                color: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                icon: Icons.account_balance_wallet,
                title: 'Доп. расходы (${orderDetails.additionalExpenses}%)',
                value: orderDetails.additionalExpensesAmount.toStringAsFixed(2),
                color: Colors.amber,
              ),
              _buildSummaryItem(
                icon: Icons.summarize,
                title: 'ИТОГО',
                value: orderDetails.totalGeneralAmount.toStringAsFixed(2),
                color: Color(0xFFFF4081),
                isHighlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isHighlighted
              ? color.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted ? color : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                fontSize: isHighlighted ? 16 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProductsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'В этом заказе пока нет товаров',
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await _showAddProductDialog(context);
            },
            icon: Icon(Icons.add_shopping_cart),
            label: Text('Добавить первый товар'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF4081),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Клиент
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            SizedBox(height: 20),

            // Заголовок
            Container(
              height: 30,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(height: 16),

            // Товары
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    height: 120,
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                },
              ),
            ),

            // Итог
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProductDialog(
      BuildContext context, OrderProduct product) async {
    final _nameController = TextEditingController(text: product.name);
    final _quantityController =
        TextEditingController(text: product.quantity.toString());
    final _priceController =
        TextEditingController(text: product.price.toString());
    File? dialogImage;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Редактировать товар',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Название товара',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFFFF4081)),
                        ),
                        prefixIcon: Icon(Icons.shopping_bag_outlined,
                            color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Количество',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFFFF4081)),
                        ),
                        prefixIcon: Icon(Icons.format_list_numbered,
                            color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Цена за единицу',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFFFF4081)),
                        ),
                        prefixIcon:
                            Icon(Icons.attach_money, color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Фото товара',
                      style: GoogleFonts.montserrat(
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile =
                            await _picker.pickImage(source: ImageSource.camera);
                        if (pickedFile != null) {
                          setState(() {
                            dialogImage = File(pickedFile.path);
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white30,
                            width: 1,
                          ),
                        ),
                        child: dialogImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white70,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Сделать фото',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  dialogImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: Icon(Icons.photo_library_outlined),
                      label: Text('Выбрать из галереи'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final pickedFile = await _picker.pickImage(
                            source: ImageSource.gallery);
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
                  child: Text(
                    'Отмена',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text(
                    'Сохранить',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF4081),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final name = _nameController.text;
                    final quantity =
                        int.tryParse(_quantityController.text) ?? 0;
                    final price = double.tryParse(_priceController.text) ?? 0.0;

                    if (name.isNotEmpty && quantity > 0 && price > 0) {
                      _editProductInOrder(
                          product.id, name, quantity, price, dialogImage);
                      Navigator.of(context).pop();
                    } else {
                      _showSnackBar(
                          'Пожалуйста, заполните все поля корректно', true);
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
          backgroundColor: Color(0xFF1A237E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Подтверждение удаления',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите удалить этот товар?',
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Отмена',
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(
                'Удалить',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
  final double additionalExpenses;
  final List<OrderProduct> products;
  final double totalPriceWithoutVat;
  final double totalPriceWithVat;
  final double additionalExpensesAmount;
  final double totalGeneralAmount;

  OrderDetails({
    required this.client,
    required this.vat,
    required this.additionalExpenses,
    required this.products,
    required this.totalPriceWithoutVat,
    required this.totalPriceWithVat,
    required this.additionalExpensesAmount,
    required this.totalGeneralAmount,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    var productsList = (json['products'] as List?)
            ?.map((productJson) => OrderProduct.fromJson(productJson))
            .toList() ??
        [];

    return OrderDetails(
      client: json['client'],
      vat: double.tryParse(json['vat']?.toString() ?? '0.0') ?? 0.0,
      additionalExpenses:
          double.tryParse(json['additional_expenses']?.toString() ?? '0.0') ??
              0.0,
      products: productsList,
      totalPriceWithoutVat: double.tryParse(
              json['total_price_without_vat']?.toString() ?? '0.0') ??
          0.0,
      totalPriceWithVat:
          double.tryParse(json['total_price_with_vat']?.toString() ?? '0.0') ??
              0.0,
      additionalExpensesAmount: double.tryParse(
              json['additional_expenses_amount']?.toString() ?? '0.0') ??
          0.0,
      totalGeneralAmount:
          double.tryParse(json['total_general_amount']?.toString() ?? '0.0') ??
              0.0,
    );
  }
}
