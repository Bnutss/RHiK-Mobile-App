import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'order_detail_page.dart';
import 'add_order_page.dart';
import 'edit_order_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Order>> _orders;
  String _selectedStatus = 'Все';
  bool _isRefreshing = false;
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
    _orders = fetchOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Order>> fetchOrders() async {
    setState(() {
      _isRefreshing = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      setState(() {
        _isRefreshing = false;
      });
      throw Exception('Токен авторизации не найден');
    }

    try {
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
        } else if (_selectedStatus == 'Не обработан') {
          orders = orders
              .where((order) => !order.isConfirmed && !order.isRejected)
              .toList();
        }

        setState(() {
          _isRefreshing = false;
        });
        return orders;
      } else {
        setState(() {
          _isRefreshing = false;
        });
        throw Exception('Не удалось загрузить заказы: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      throw Exception('Ошибка: $e');
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
      _showSnackBar('Заказ успешно удален', isError: false);
    } else {
      _showSnackBar('Ошибка при удалении заказа', isError: true);
    }
  }

  Future<void> _showExportDialog(int orderId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A237E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Выберите формат',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: Text(
                  'Отправить в Excel',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportOrder(orderId, 'excel');
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: Colors.white.withOpacity(0.05),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(
                  'Отправить в PDF',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportOrder(orderId, 'pdf');
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: Colors.white.withOpacity(0.05),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Отмена',
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmOrder(int orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    try {
      final response = await http.patch(
        Uri.parse(
            'https://rhik.pythonanywhere.com/sales/api/orders/$orderId/confirm/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _refreshOrders();
        _showSnackBar('Заказ подтвержден', isError: false);
      } else {
        _showSnackBar('Не удалось подтвердить заказ', isError: true);
      }
    } catch (e) {
      _showSnackBar('Ошибка: $e', isError: true);
    }
  }

  Future<void> _rejectOrder(int orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    try {
      final response = await http.patch(
        Uri.parse(
            'https://rhik.pythonanywhere.com/sales/api/orders/$orderId/reject/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _refreshOrders();
        _showSnackBar('Заказ отклонен', isError: false);
      } else {
        _showSnackBar('Не удалось отклонить заказ', isError: true);
      }
    } catch (e) {
      _showSnackBar('Ошибка: $e', isError: true);
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
        _showSnackBar('Заказ успешно экспортирован в формате $format',
            isError: false);
      } else {
        _showSnackBar('Ошибка при экспорте заказа в формате $format',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Произошла ошибка: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
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

  void _showDeleteConfirmation(int orderId) {
    showDialog(
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
            'Вы уверены, что хотите удалить этот заказ?',
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Отмена',
                style: GoogleFonts.montserrat(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteOrder(orderId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Удалить',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showOrderOptions(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A237E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Действия с заказом',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildActionTile(
                icon: Icons.visibility_outlined,
                color: Colors.blue,
                title: 'Просмотр деталей',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailPage(orderId: order.id),
                    ),
                  );
                },
              ),
              _buildActionTile(
                icon: Icons.edit_outlined,
                color: Colors.amber,
                title: 'Редактировать',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditOrderPage(orderId: order.id),
                    ),
                  );
                },
              ),
              _buildActionTile(
                icon: Icons.send_outlined,
                color: Colors.green,
                title: 'Отправить по телеграмму',
                onTap: () {
                  Navigator.pop(context);
                  _showExportDialog(order.id);
                },
              ),
              if (!order.isConfirmed && !order.isRejected)
                _buildActionTile(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  title: 'Подтвердить заказ',
                  onTap: () {
                    Navigator.pop(context);
                    _confirmOrder(order.id);
                  },
                ),
              if (!order.isConfirmed && !order.isRejected)
                _buildActionTile(
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  title: 'Отклонить заказ',
                  onTap: () {
                    Navigator.pop(context);
                    _rejectOrder(order.id);
                  },
                ),
              _buildActionTile(
                icon: Icons.delete_outline,
                color: Colors.red,
                title: 'Удалить заказ',
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(order.id);
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          color: Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData chipIcon;

    switch (status) {
      case 'Подтвержден':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        break;
      case 'Отклонен':
        chipColor = Colors.red;
        chipIcon = Icons.cancel;
        break;
      default:
        chipColor = Colors.orange;
        chipIcon = Icons.pending;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipIcon,
            color: chipColor,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            status,
            style: GoogleFonts.montserrat(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.5),
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            '$title: ',
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Все'),
          SizedBox(width: 8),
          _buildFilterChip('Подтвержден'),
          SizedBox(width: 8),
          _buildFilterChip('Отклонен'),
          SizedBox(width: 8),
          _buildFilterChip('Не обработан'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status) {
    bool isSelected = _selectedStatus == status;

    Color chipColor;
    IconData chipIcon;

    switch (status) {
      case 'Подтвержден':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        break;
      case 'Отклонен':
        chipColor = Colors.red;
        chipIcon = Icons.cancel;
        break;
      case 'Не обработан':
        chipColor = Colors.orange;
        chipIcon = Icons.pending;
        break;
      default:
        chipColor = Color(0xFFFF4081);
        chipIcon = Icons.all_inclusive;
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
          _orders = fetchOrders();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chipIcon,
              color: isSelected ? chipColor : Colors.white.withOpacity(0.7),
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              status,
              style: GoogleFonts.montserrat(
                color: isSelected ? chipColor : Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.2),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'Нет заказов в выбранной категории',
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedStatus = 'Все';
                _orders = fetchOrders();
              });
            },
            icon: Icon(Icons.refresh),
            label: Text('Показать все заказы'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Заказы',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshOrders,
            tooltip: 'Обновить',
          ),
        ],
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
            child: Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: _isRefreshing
                      ? _buildLoadingShimmer()
                      : FutureBuilder<List<Order>>(
                          future: _orders,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingShimmer();
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Ошибка: ${snapshot.error}',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            } else if (snapshot.hasData) {
                              final orders = snapshot.data!;

                              if (orders.isEmpty) {
                                return _buildEmptyState();
                              }

                              return RefreshIndicator(
                                onRefresh: _refreshOrders,
                                color: Color(0xFFFF4081),
                                backgroundColor: Colors.white,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: orders.length,
                                  physics: AlwaysScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final order = orders[index];
                                    final warrantyDaysLeft =
                                        order.warrantyDaysLeft != null
                                            ? '${order.warrantyDaysLeft} дней'
                                            : 'Нет гарантии';
                                    final status = order.isConfirmed
                                        ? 'Подтвержден'
                                        : order.isRejected
                                            ? 'Отклонен'
                                            : 'Не обработан';

                                    return Animate(
                                      effects: [
                                        FadeEffect(
                                            duration: 300.ms,
                                            delay: (50 * index).ms)
                                      ],
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrderDetailPage(
                                                      orderId: order.id),
                                            ),
                                          );
                                        },
                                        onLongPress: () {
                                          _showOrderOptions(order);
                                        },
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              // Заголовок карточки заказа
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        color: Color(0xFFFF4081)
                                                            .withOpacity(0.2),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Center(
                                                        child: Icon(
                                                          Icons
                                                              .shopping_bag_outlined,
                                                          color:
                                                              Color(0xFFFF4081),
                                                          size: 24,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            order.client,
                                                            style: GoogleFonts
                                                                .montserrat(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          SizedBox(height: 4),
                                                          _buildStatusChip(
                                                              status),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.more_vert,
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                      ),
                                                      onPressed: () {
                                                        _showOrderOptions(
                                                            order);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Детали заказа
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        16, 0, 16, 16),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _buildInfoRow(
                                                                  Icons
                                                                      .attach_money,
                                                                  'НДС',
                                                                  '${order.vat}%'),
                                                              _buildInfoRow(
                                                                  Icons
                                                                      .monetization_on,
                                                                  'Доп. расходы',
                                                                  '${order.additionalExpenses}%'),
                                                              _buildInfoRow(
                                                                  Icons.shield,
                                                                  'Гарантия',
                                                                  warrantyDaysLeft),
                                                            ],
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _buildInfoRow(
                                                                  Icons
                                                                      .money_off,
                                                                  'Расходы',
                                                                  '${order.additionalExpensesAmount?.toStringAsFixed(2) ?? "0.00"}'),
                                                              _buildInfoRow(
                                                                  Icons
                                                                      .money_off,
                                                                  'Без НДС',
                                                                  '${order.totalPriceWithoutVat ?? "0.00"}'),
                                                              _buildInfoRow(
                                                                  Icons
                                                                      .attach_money,
                                                                  'Итого',
                                                                  '${order.totalPriceWithVat ?? "0.00"}',
                                                                  isHighlighted:
                                                                      true),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    // Кнопки действий
                                                    if (!order.isConfirmed &&
                                                        !order.isRejected)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                top: 12.0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            ElevatedButton.icon(
                                                              onPressed: () =>
                                                                  _rejectOrder(
                                                                      order.id),
                                                              icon: Icon(
                                                                  Icons
                                                                      .cancel_outlined,
                                                                  size: 16),
                                                              label: Text(
                                                                  'Отклонить'),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors.red
                                                                        .shade700
                                                                        .withOpacity(
                                                                            0.8),
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            12,
                                                                        vertical:
                                                                            6),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20),
                                                                ),
                                                                textStyle:
                                                                    GoogleFonts
                                                                        .montserrat(
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 8),
                                                            ElevatedButton.icon(
                                                              onPressed: () =>
                                                                  _confirmOrder(
                                                                      order.id),
                                                              icon: Icon(
                                                                  Icons
                                                                      .check_circle_outline,
                                                                  size: 16),
                                                              label: Text(
                                                                  'Подтвердить'),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors.green
                                                                        .shade700
                                                                        .withOpacity(
                                                                            0.8),
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            12,
                                                                        vertical:
                                                                            6),
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20),
                                                                ),
                                                                textStyle:
                                                                    GoogleFonts
                                                                        .montserrat(
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddOrderPage()),
          );
        },
        backgroundColor: Color(0xFFFF4081),
        child: const Icon(Icons.add),
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
      vat: json['vat'] != null
          ? double.tryParse(json['vat'].toString()) ?? 0.0
          : 0.0,
      additionalExpenses: json['additional_expenses'] != null
          ? double.tryParse(json['additional_expenses'].toString()) ?? 0.0
          : 0.0,
      isConfirmed: json['is_confirmed'],
      isRejected: json['is_rejected'],
      warrantyDaysLeft: json['warranty_days_left'],
      totalPriceWithoutVat: json['total_price_without_vat'] != null
          ? double.tryParse(json['total_price_without_vat'].toString()) ?? 0.0
          : 0.0,
      totalPriceWithVat: json['total_price_with_vat'] != null
          ? double.tryParse(json['total_price_with_vat'].toString()) ?? 0.0
          : 0.0,
    );
  }

  double? get additionalExpensesAmount {
    if (additionalExpenses != null && totalPriceWithoutVat != null) {
      return totalPriceWithoutVat! * (additionalExpenses! / 100);
    }
    return null;
  }
}
