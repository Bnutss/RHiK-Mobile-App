import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'api_client.dart';
import 'order_detail_page.dart';
import 'add_order_page.dart';
import 'edit_order_page.dart';
import 'widgets/app_toast.dart';

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

  // Цвета Hikvision
  final Color hikRed = Color(0xFFE31E24);
  final Color visionGray = Color(0xFF707070);
  final Color darkGray = Color(0xFF333333);

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

    try {
      final response = await apiGet(
        Uri.parse('https://rhik.uz/sales/api/orders/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        List<Order> orders = data.map((json) => Order.fromJson(json)).toList();
        orders.sort((a, b) => b.id.compareTo(a.id));

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
    try {
      final response = await apiDelete(
        Uri.parse('https://rhik.uz/sales/api/orders/$orderId/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      if (response.statusCode == 204) {
        _refreshOrders();
        _showSnackBar('Заказ успешно удален', isError: false);
      } else {
        _showSnackBar('Ошибка при удалении заказа', isError: true);
      }
    } catch (e) {
      _showSnackBar('Ошибка: $e', isError: true);
    }
  }

  Future<void> _showExportDialog(int orderId) async {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Выберите формат',
      message: 'Куда отправить заказ?',
      actions: [
        AlertAction(
          title: 'Excel',
          onPressed: () => _exportOrder(orderId, 'excel'),
        ),
        AlertAction(
          title: 'PDF',
          onPressed: () => _exportOrder(orderId, 'pdf'),
        ),
        AlertAction(
          title: 'Отмена',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
      ],
    );
  }

  Future<void> _confirmOrder(int orderId) async {
    try {
      final response = await apiPatch(
        Uri.parse('https://rhik.uz/sales/api/orders/$orderId/confirm/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
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
    try {
      final response = await apiPatch(
        Uri.parse('https://rhik.uz/sales/api/orders/$orderId/reject/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
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
    final url =
        'https://rhik.uz/sales/api/orders/$orderId/export_to_telegram/?file_type=$format';

    try {
      final response = await apiPost(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnackBar('Заказ успешно экспортирован в формате $format',
            isError: false);
      } else {
        _showSnackBar('Ошибка при экспорте заказа в формате $format',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Произошла ошибка: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    showAppToast(context, message, isError: isError);
  }

  void _showDeleteConfirmation(int orderId) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Подтверждение удаления',
      message: 'Вы уверены, что хотите удалить этот заказ?',
      actions: [
        AlertAction(
          title: 'Отмена',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'Удалить',
          style: AlertActionStyle.destructive,
          onPressed: () => _deleteOrder(orderId),
        ),
      ],
    );
  }

  void _showOrderOptions(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: visionGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Действия с заказом',
                style: GoogleFonts.montserrat(
                  color: hikRed,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildActionTile(
                icon: Icons.visibility_outlined,
                color: visionGray,
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
                color: visionGray,
                title: 'Редактировать',
                onTap: () async {
                  Navigator.pop(context);
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditOrderPage(orderId: order.id),
                    ),
                  );
                  if (updated == true) {
                    _refreshOrders();
                    _showSnackBar('Заказ успешно обновлен', isError: false);
                  }
                },
              ),
              _buildActionTile(
                icon: Icons.send_outlined,
                color: hikRed,
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
                  color: hikRed,
                  title: 'Отклонить заказ',
                  onTap: () {
                    Navigator.pop(context);
                    _rejectOrder(order.id);
                  },
                ),
              _buildActionTile(
                icon: Icons.delete_outline,
                color: hikRed,
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
          color: color.withOpacity(0.1),
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
          color: darkGray,
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
        chipColor = hikRed;
        chipIcon = Icons.cancel;
        break;
      default:
        chipColor = visionGray;
        chipIcon = Icons.pending;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
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
            color: visionGray,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            '$title: ',
            style: GoogleFonts.montserrat(
              color: visionGray,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: isHighlighted ? hikRed : darkGray,
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
        chipColor = hikRed;
        chipIcon = Icons.cancel;
        break;
      case 'Не обработан':
        chipColor = visionGray;
        chipIcon = Icons.pending;
        break;
      default:
        chipColor = hikRed;
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
          color: isSelected ? chipColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : visionGray.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chipIcon,
              color: isSelected ? chipColor : visionGray,
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              status,
              style: GoogleFonts.montserrat(
                color: isSelected ? chipColor : visionGray,
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
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
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
            size: 70,
            color: visionGray.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'Нет заказов в выбранной категории',
            style: GoogleFonts.montserrat(
              color: visionGray,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      useHeroBackButton: false,
      appBar: AdaptiveAppBar(
        title: 'Заказы',
        useNativeToolbar: true,
        actions: [
          AdaptiveAppBarAction(
            iosSymbol: 'plus',
            icon: Icons.add,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddOrderPage()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            minimum: EdgeInsets.only(
              bottom: PlatformInfo.isIOS26OrHigher() ? 90.0 : 0.0,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
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
                                        color: darkGray,
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
                                  color: hikRed,
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
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                // Заголовок карточки заказа
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      16.0),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 50,
                                                        height: 50,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: hikRed
                                                              .withOpacity(0.1),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: Center(
                                                          child: Icon(
                                                            Icons
                                                                .shopping_bag_outlined,
                                                            color: hikRed,
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
                                                                color: darkGray,
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
                                                          color: visionGray,
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
                                                                if (order.advance !=
                                                                    null)
                                                                  _buildInfoRow(
                                                                      Icons
                                                                          .payments_outlined,
                                                                      'Аванс',
                                                                      order
                                                                          .advance!
                                                                          .toStringAsFixed(
                                                                              2)),
                                                                _buildInfoRow(
                                                                    Icons
                                                                        .shield,
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
                                                              ElevatedButton
                                                                  .icon(
                                                                onPressed: () =>
                                                                    _rejectOrder(
                                                                        order
                                                                            .id),
                                                                icon: Icon(
                                                                  Icons
                                                                      .cancel_outlined,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 14,
                                                                ),
                                                                label: Text(
                                                                  'Отклонить',
                                                                  style: GoogleFonts
                                                                      .montserrat(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      hikRed,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                  padding:
                                                                      EdgeInsets
                                                                          .symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical: 6,
                                                                  ),
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20),
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  width: 8),
                                                              ElevatedButton
                                                                  .icon(
                                                                onPressed: () =>
                                                                    _confirmOrder(
                                                                        order
                                                                            .id),
                                                                icon: Icon(
                                                                  Icons
                                                                      .check_circle_outline,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 14,
                                                                ),
                                                                label: Text(
                                                                  'Подтвердить',
                                                                  style: GoogleFonts
                                                                      .montserrat(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                  padding:
                                                                      EdgeInsets
                                                                          .symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical: 6,
                                                                  ),
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20),
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
                                      color: darkGray,
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
      ),
    );
  }
}

class Order {
  final int id;
  final String client;
  final double vat;
  final double? additionalExpenses;
  final double? advance;
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
    this.advance,
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
      advance: json['advance'] != null
          ? double.tryParse(json['advance'].toString())
          : null,
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
