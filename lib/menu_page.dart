import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'api_client.dart';
import 'info_page.dart';
import 'results_day_page.dart';
import 'orders_page.dart';
import 'passwords_page.dart';

/// The native iOS 26+ tab bar only renders SF Symbol name strings; the
/// Android fallback only renders [IconData] (a string is shown as a plain
/// circle there). Pick the right type per platform so both render properly.
dynamic _navIcon({required String sfSymbol, required IconData material}) {
  return Platform.isIOS ? sfSymbol : material;
}

class MenuPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const MenuPage({Key? key, required this.userData, required this.token})
      : super(key: key);

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _selectedIndex = 0;

  late final List<Widget> _tabs = [
    _HomeTab(
      userData: widget.userData,
      onNavigate: (index) => setState(() => _selectedIndex = index),
    ),
    OrdersPage(),
    ResultsDayPage(),
    PasswordsPage(),
    SettingsPage(userData: widget.userData, token: widget.token),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        useNativeBottomBar: true,
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFF707070),
        items: [
          AdaptiveNavigationDestination(
            icon: _navIcon(sfSymbol: 'house', material: Icons.home_outlined),
            selectedIcon:
                _navIcon(sfSymbol: 'house.fill', material: Icons.home),
            label: 'Главная',
          ),
          AdaptiveNavigationDestination(
            icon: _navIcon(
                sfSymbol: 'bag', material: Icons.shopping_bag_outlined),
            selectedIcon:
                _navIcon(sfSymbol: 'bag.fill', material: Icons.shopping_bag),
            label: 'Заказы',
          ),
          AdaptiveNavigationDestination(
            icon: _navIcon(
                sfSymbol: 'chart.bar.fill', material: Icons.bar_chart_rounded),
            label: 'Итоги дня',
          ),
          AdaptiveNavigationDestination(
            icon: _navIcon(
                sfSymbol: 'key.fill', material: Icons.vpn_key_outlined),
            label: 'Пароли',
          ),
          AdaptiveNavigationDestination(
            icon: _navIcon(sfSymbol: 'gear', material: Icons.settings_outlined),
            label: 'Настройки',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  final ValueChanged<int> onNavigate;

  const _HomeTab({required this.userData, required this.onNavigate});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Фирменная палитра HIKVISION
  final Color hikRed = Color(0xFFE31E24);
  final Color hikRedDark = Color(0xFFAE1015);
  final Color graphite = Color(0xFF1C1C1E);
  final Color visionGray = Color(0xFF707070);
  final Color darkGray = Color(0xFF333333);

  bool _isLoadingStats = true;
  int _ordersCount = 0;
  int _confirmedOrdersCount = 0;
  double _confirmedTotal = 0.0;
  int _passwordsCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    _loadDashboardStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoadingStats = true);

    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('access_token');
    if (token == null) {
      if (mounted) setState(() => _isLoadingStats = false);
      return;
    }

    Map<String, String> headers(String t) => {
          'Authorization': 'Bearer $t',
          'Content-Type': 'application/json',
        };

    final urls = [
      Uri.parse('https://rhik.uz/sales/api/orders/'),
      Uri.parse('https://rhik.uz/sales/api/confirmed-orders/'),
      Uri.parse('https://rhik.uz/sales/api/passwords/'),
    ];

    try {
      var responses = await Future.wait(
        urls.map((url) => http.get(url, headers: headers(token!))),
      );

      // Все три запроса используют один и тот же access_token, так что
      // достаточно одного обновления токена на всю пачку, а не по одному
      // на запрос: сервер выпускает новый refresh_token на каждый вызов
      // /api/token/refresh/ и блокирует старый, поэтому параллельные
      // попытки обновления токена приводили бы к гонке.
      if (responses.any((r) => r.statusCode == 401)) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          token = prefs.getString('access_token');
          responses = await Future.wait(
            urls.map((url) => http.get(url, headers: headers(token!))),
          );
        }
      }

      if (responses[0].statusCode == 200) {
        _ordersCount =
            (json.decode(utf8.decode(responses[0].bodyBytes)) as List).length;
      }
      if (responses[1].statusCode == 200) {
        final data = json.decode(utf8.decode(responses[1].bodyBytes));
        _confirmedOrdersCount = (data['orders'] as List).length;
        _confirmedTotal = (data['total_sum'] as num).toDouble();
      }
      if (responses[2].statusCode == 200) {
        _passwordsCount =
            (json.decode(utf8.decode(responses[2].bodyBytes)) as List).length;
      }
    } catch (_) {
      // Показываем нули, если не удалось получить статистику
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  void _logout(BuildContext context) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Выход',
      message: 'Вы уверены, что хотите выйти?',
      icon: _navIcon(
          sfSymbol: 'rectangle.portrait.and.arrow.right',
          material: Icons.logout),
      iconColor: hikRed,
      actions: [
        AlertAction(
          title: 'Отмена',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'Выйти',
          style: AlertActionStyle.destructive,
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    );
  }

  String get _displayName {
    final firstName = (widget.userData['first_name'] as String?)?.trim();
    final lastName = (widget.userData['last_name'] as String?)?.trim();
    final fullName = [firstName, lastName]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) return fullName;
    return (widget.userData['username'] as String?)?.trim() ?? 'Пользователь';
  }

  String get _userInitial {
    final name = _displayName;
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AdaptiveScaffold(
        useHeroBackButton: false,
        appBar: AdaptiveAppBar(
          useNativeToolbar: true,
          actions: [
            AdaptiveAppBarAction(
              iosSymbol: 'rectangle.portrait.and.arrow.right',
              icon: Icons.logout,
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Фирменный фон-подложка
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey[100]!, Colors.grey[200]!],
                ),
              ),
            ),
            Positioned(
              top: -100,
              right: -100,
              child: _decorCircle(300, hikRed.withOpacity(0.05)),
            ),
            Positioned(
              bottom: -60,
              left: -80,
              child: _decorCircle(200, visionGray.withOpacity(0.05)),
            ),
            SafeArea(
              minimum: EdgeInsets.only(
                bottom: PlatformInfo.isIOS26OrHigher() ? 90.0 : 0.0,
              ),
              child: RefreshIndicator(
                color: hikRed,
                onRefresh: _loadDashboardStats,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeroHeader()),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _sectionLabel('ОБЗОР'),
                              const SizedBox(height: 14),
                              _buildOverviewGrid(),
                              const SizedBox(height: 36),
                              Center(
                                child: Text(
                                  'XVAN RUSLAN PRODUCTION',
                                  style: GoogleFonts.montserrat(
                                    color: visionGray.withOpacity(0.45),
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: visionGray,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [hikRed, hikRedDark],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: hikRed.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -36,
                right: -28,
                child: _decorCircle(120, Colors.white.withOpacity(0.08)),
              ),
              Positioned(
                bottom: -44,
                right: 56,
                child: _decorCircle(80, Colors.white.withOpacity(0.06)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _userInitial,
                      style: GoogleFonts.montserrat(
                        color: hikRed,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Добро пожаловать',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              _displayName,
                              textStyle: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              speed: const Duration(milliseconds: 90),
                            ),
                          ],
                          totalRepeatCount: 1,
                          isRepeatingAnimation: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          title: 'Заказы',
          value: '$_ordersCount',
          material: Icons.shopping_bag_outlined,
          accent: hikRed,
        ),
        _buildStatCard(
          title: 'Подтверждено',
          value: '$_confirmedOrdersCount',
          material: Icons.check_circle_outline,
          accent: graphite,
        ),
        _buildStatCard(
          title: 'Сумма за день',
          value: _confirmedTotal.toStringAsFixed(2),
          material: Icons.bar_chart_rounded,
          accent: hikRed,
        ),
        _buildStatCard(
          title: 'Пароли',
          value: '$_passwordsCount',
          material: Icons.vpn_key_outlined,
          accent: graphite,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData material,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(material, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _isLoadingStats
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 40,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: GoogleFonts.montserrat(
                          color: darkGray,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: visionGray,
                    fontSize: 11.5,
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
