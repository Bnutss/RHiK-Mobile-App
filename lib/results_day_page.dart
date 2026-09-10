import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'api_client.dart';
import 'widgets/app_toast.dart';

class ResultsDayPage extends StatefulWidget {
  @override
  _ResultsDayPageState createState() => _ResultsDayPageState();
}

class _ResultsDayPageState extends State<ResultsDayPage>
    with SingleTickerProviderStateMixin {
  List orders = [];
  double totalSum = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPreset = 'all';
  static const List<String> _presetKeys = [
    'all',
    'today',
    'week',
    'month',
    'custom',
  ];
  static const List<String> _presetLabels = [
    'Всё время',
    'Сегодня',
    'Неделя',
    'Месяц',
    'Свой период',
  ];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedTabIndex = 0;

  // Используем ту же цветовую схему, что и в LoginPage
  final Color hikRed = Color(0xFFE31E24);
  final Color visionGray = Color(0xFF707070);
  final Color darkGray = Color(0xFF333333);
  final Color lightGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    fetchConfirmedOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTime tempStart = _startDate ?? DateTime.now();
    DateTime tempEnd = _endDate ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, 20 + MediaQuery.of(sheetContext).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: visionGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    'Выберите период',
                    style: GoogleFonts.montserrat(
                      color: darkGray,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildDatePickerRow(
                    context: sheetContext,
                    label: 'С',
                    value: tempStart,
                    onChanged: (d) => setSheetState(() => tempStart = d),
                  ),
                  SizedBox(height: 12),
                  _buildDatePickerRow(
                    context: sheetContext,
                    label: 'По',
                    value: tempEnd,
                    onChanged: (d) => setSheetState(() => tempEnd = d),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        setState(() {
                          _startDate = tempStart;
                          _endDate = tempEnd;
                          _selectedPreset = 'custom';
                          _isLoading = true;
                        });
                        fetchConfirmedOrders();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hikRed,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Применить',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDatePickerRow({
    required BuildContext context,
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await AdaptiveDatePicker.show(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: lightGray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: visionGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  DateFormat('dd.MM.yyyy').format(value),
                  style: GoogleFonts.montserrat(
                    color: darkGray,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 16, color: visionGray),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (preset) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        end = now;
        break;
      case 'week':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = now;
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        end = now;
        break;
      case 'all':
        start = null;
        end = null;
        break;
    }

    setState(() {
      _selectedPreset = preset;
      _startDate = start;
      _endDate = end;
      _isLoading = true;
    });
    fetchConfirmedOrders();
  }

  Future<void> fetchConfirmedOrders() async {
    setState(() {
      _isLoading = true;
    });

    final String? startDate = _startDate != null
        ? DateFormat('yyyy-MM-dd').format(_startDate!)
        : null;
    final String? endDate =
        _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    final queryParameters = {
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };
    final uri = Uri.https(
      'rhik.uz',
      '/sales/api/confirmed-orders/',
      queryParameters,
    );

    try {
      final response = await apiGet(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          orders = data['orders'];
          totalSum = (data['total_sum'] as num).toDouble();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Ошибка получения заказов: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Ошибка соединения с сервером');
    }
  }

  /// The server always sends timestamps with a Tashkent (+05:00) offset.
  /// `DateTime.parse` converts that instant to the device's own timezone,
  /// which shifts the displayed time when the device isn't set to +05:00.
  /// Re-apply the Tashkent offset so the displayed time always matches what
  /// the server meant, regardless of the device's local timezone.
  DateTime _parseServerDate(String value) {
    return DateTime.parse(value).toUtc().add(const Duration(hours: 5));
  }

  void _showError(String message) {
    showAppToast(context, message, isError: true);
  }

  Future<void> _refreshOrders() async {
    await fetchConfirmedOrders();
  }

  @override
  Widget build(BuildContext context) {
    String dateRangeText = 'Все заказы';
    if (_startDate != null && _endDate != null) {
      final startFormatted = DateFormat('dd.MM.yyyy').format(_startDate!);
      final endFormatted = DateFormat('dd.MM.yyyy').format(_endDate!);
      dateRangeText = '$startFormatted - $endFormatted';
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AdaptiveScaffold(
        useHeroBackButton: false,
        appBar: AdaptiveAppBar(
          title: 'Итоги дня',
          useNativeToolbar: true,
          actions: [
            AdaptiveAppBarAction(
              iosSymbol: 'calendar',
              icon: Icons.calendar_today,
              onPressed: () => _selectDateRange(context),
            ),
          ],
        ),
        body: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Фоновый градиент как в LoginPage
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.grey[100]!,
                      Colors.grey[200]!,
                    ],
                  ),
                ),
              ),
              // Декоративные круги как в LoginPage
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hikRed.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: visionGray.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        hikRed.withOpacity(0.9),
                        hikRed.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                minimum: EdgeInsets.only(
                  bottom: PlatformInfo.isIOS26OrHigher() ? 90.0 : 0.0,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 12),
                    // Быстрые пресеты периода
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AdaptiveSegmentedControl(
                        labels: _presetLabels,
                        selectedIndex: _presetKeys.indexOf(_selectedPreset),
                        color: hikRed,
                        onValueChanged: (index) {
                          final preset = _presetKeys[index];
                          if (preset == 'custom') {
                            _selectDateRange(context);
                          } else {
                            _applyPreset(preset);
                          }
                        },
                      ),
                    ),
                    // Период дат
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.date_range,
                            color: visionGray,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            dateRangeText,
                            style: GoogleFonts.montserrat(
                              color: darkGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Переключатель вкладок
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _buildTabButton(0, 'Список'),
                          _buildTabButton(1, 'Статистика'),
                        ],
                      ),
                    ),
                    // Контент
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _selectedTabIndex == 0
                            ? _buildOrdersList()
                            : _buildStatisticsView(),
                      ),
                    ),
                    // Итоговая сумма
                    _buildTotalSumBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    bool isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? hikRed : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                color: isSelected ? Colors.white : visionGray,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

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
          DateTime orderDate = _parseServerDate(order['created_at']);
          String formattedDate =
              DateFormat('dd.MM.yyyy HH:mm').format(orderDate);

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: hikRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: hikRed,
                      size: 24,
                    ),
                  ),
                ),
                title: Text(
                  'Клиент: ${order['client']}',
                  style: GoogleFonts.montserrat(
                    color: darkGray,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Стоимость: ${order['total_price_with_vat']}',
                          style: GoogleFonts.montserrat(
                            color: visionGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: visionGray,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: GoogleFonts.montserrat(
                            color: visionGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: visionGray,
                  size: 16,
                ),
                onTap: () {
                  _showOrderDetails(order);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsView() {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    final Map<DateTime, double> dailyTotalsMap = {};
    for (var order in orders) {
      final orderDate = _parseServerDate(order['created_at']);
      final dayKey = DateTime(orderDate.year, orderDate.month, orderDate.day);
      final price = double.parse(order['total_price_with_vat'].toString());
      dailyTotalsMap.update(dayKey, (existing) => existing + price,
          ifAbsent: () => price);
    }

    final sortedDays = dailyTotalsMap.keys.toList()..sort();
    final days =
        sortedDays.map((d) => DateFormat('dd.MM').format(d)).toList();
    final values = sortedDays.map((d) => dailyTotalsMap[d]!).toList();
    final averagePerDay = values.isNotEmpty
        ? values.reduce((a, b) => a + b) / values.length
        : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartCard(days, values, averagePerDay),
          SizedBox(height: 20),
          _buildHeroStatCard(),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Заказов',
                  value: orders.length.toString(),
                  color: Color(0xFF2E7D32),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Средний чек',
                  value: _formatMoney(
                      orders.isNotEmpty ? totalSum / orders.length : 0),
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Formats a monetary value with space-separated thousands, e.g. 30846.94
  /// becomes "30 846.94".
  String _formatMoney(double value) {
    final isNegative = value < 0;
    final parts = value.abs().toStringAsFixed(2).split('.');
    final wholeDigits = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < wholeDigits.length; i++) {
      final remaining = wholeDigits.length - i;
      if (i != 0 && remaining % 3 == 0) buffer.write(' ');
      buffer.write(wholeDigits[i]);
    }
    return '${isNegative ? '-' : ''}${buffer.toString()}.${parts[1]}';
  }

  /// Compact axis labels: 1200 -> "1.2K", 950 -> "950".
  String _formatCompact(double value) {
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return value.toInt().toString();
  }

  String _daysWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'день';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'дня';
    }
    return 'дней';
  }

  Widget _buildChartCard(
      List<String> days, List<double> values, double averagePerDay) {
    final maxValue =
        values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0.0;
    final chartMaxY = maxValue > 0 ? maxValue * 1.3 : 100.0;
    final labelStep = days.length > 6 ? (days.length / 5).ceil() : 1;
    final periodTotal = values.fold<double>(0, (sum, v) => sum + v);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Продажи по дням',
                      style: GoogleFonts.montserrat(
                        color: darkGray,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '${days.length} ${_daysWord(days.length)} · в среднем ${_formatMoney(averagePerDay)}/день',
                      style: GoogleFonts.montserrat(
                        color: visionGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hikRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatMoney(periodTotal),
                  style: GoogleFonts.montserrat(
                    color: hikRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 26),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: darkGray,
                    tooltipRoundedRadius: 10,
                    tooltipPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${days[groupIndex]}\n',
                        GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: _formatMoney(values[groupIndex]),
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        final isLast = index == days.length - 1;
                        if (labelStep > 1 &&
                            index % labelStep != 0 &&
                            !isLast) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            days[index],
                            style: GoogleFonts.montserrat(
                              color: visionGray,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          _formatCompact(value),
                          style: GoogleFonts.montserrat(
                            color: visionGray,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 38,
                    ),
                  ),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: lightGray,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(days.length, (index) {
                  final isPeak = values[index] == maxValue && maxValue > 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index],
                        width: days.length > 10 ? 10 : 18,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isPeak
                              ? [hikRed, hikRed.withOpacity(0.75)]
                              : [
                                  hikRed.withOpacity(0.55),
                                  hikRed.withOpacity(0.32),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: chartMaxY,
                          color: lightGray.withOpacity(0.5),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hikRed, hikRed.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hikRed.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Общая сумма',
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _formatMoney(totalSum),
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: darkGray,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: visionGray,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 80,
            color: visionGray.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'Нет данных за выбранный период',
            style: GoogleFonts.montserrat(
              color: visionGray,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalSumBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Общая сумма:',
            style: GoogleFonts.montserrat(
              color: darkGray,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: hikRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _formatMoney(totalSum),
              style: GoogleFonts.montserrat(
                color: hikRed,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(dynamic order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: lightGray,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Детали заказа',
                      style: GoogleFonts.montserrat(
                        color: darkGray,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: visionGray),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        icon: Icons.person_outline,
                        title: 'Клиент',
                        value: order['client'] ?? 'Не указан',
                        iconColor: Colors.blue,
                      ),
                      _buildDetailItem(
                        icon: Icons.calendar_today,
                        title: 'Дата заказа',
                        value: DateFormat('dd.MM.yyyy HH:mm').format(
                          _parseServerDate(order['created_at']),
                        ),
                        iconColor: Colors.amber,
                      ),
                      _buildDetailItem(
                        icon: Icons.attach_money,
                        title: 'Стоимость',
                        value: '${order['total_price_with_vat']}',
                        iconColor: Colors.green,
                      ),
                      _buildDetailItem(
                        icon: Icons.receipt_long,
                        title: 'Номер заказа',
                        value: '#${order['id']}',
                        iconColor: hikRed,
                      ),
                      if (order['products'] != null &&
                          order['products'] is List)
                        ..._buildProductsSection(order['products']),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildProductsSection(List products) {
    return [
      SizedBox(height: 20),
      Text(
        'Товары',
        style: GoogleFonts.montserrat(
          color: darkGray,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 12),
      ...products.map((product) => _buildProductItem(product)).toList(),
    ];
  }

  Widget _buildProductItem(dynamic product) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hikRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              color: hikRed,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Товар',
                  style: GoogleFonts.montserrat(
                    color: darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Количество: ${product['quantity']} × ${product['price']}',
                  style: GoogleFonts.montserrat(
                    color: visionGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(product['quantity'] * product['price']).toStringAsFixed(2)}',
            style: GoogleFonts.montserrat(
              color: darkGray,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: visionGray,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    color: darkGray,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
