import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'widgets/app_toast.dart';

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({Key? key}) : super(key: key);

  @override
  State<PasswordsPage> createState() => _PasswordsPageState();
}

class _PasswordsPageState extends State<PasswordsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> passwords = [];
  List<dynamic> filteredPasswords = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Цвета Hikvision
  final Color hikRed = Color(0xFFE31E24);
  final Color visionGray = Color(0xFF707070);
  final Color darkGray = Color(0xFF333333);
  final Color lightGray = Color(0xFFF5F5F5);

  Map<int, bool> _expandedItems = {};

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
    fetchPasswords();
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> fetchPasswords() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        _showSnackBar('Токен не найден. Пожалуйста, войдите заново.',
            isError: true);
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://26.6.96.21:8000/sales/api/passwords/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          passwords = data;
          filteredPasswords = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showSnackBar('Ошибка загрузки: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Ошибка подключения к серверу.', isError: true);
    }
  }

  void filterPasswords(String query) {
    setState(() {
      filteredPasswords = passwords.where((password) {
        final organizationName =
            password['organization_name'].toString().toLowerCase();
        return organizationName.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> addOrEditPassword({
    int? id,
    required String organizationName,
    required String nvrPassword,
    required String cameraPassword,
  }) async {
    if (organizationName.isEmpty) {
      _showSnackBar('Пожалуйста, введите название организации', isError: true);
      return;
    }

    final token = await _getToken();
    if (token == null) {
      _showSnackBar('Токен не найден. Пожалуйста, войдите заново.',
          isError: true);
      return;
    }

    try {
      final response = id == null
          ? await http.post(
              Uri.parse('http://26.6.96.21:8000/sales/api/passwords/'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'organization_name': organizationName,
                'nvr_password': nvrPassword,
                'camera_password': cameraPassword,
              }),
            )
          : await http.put(
              Uri.parse('http://26.6.96.21:8000/sales/api/passwords/$id/'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'organization_name': organizationName,
                'nvr_password': nvrPassword,
                'camera_password': cameraPassword,
              }),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchPasswords();
        _showSnackBar(
            id == null
                ? 'Запись успешно добавлена'
                : 'Запись успешно обновлена',
            isError: false);
      } else {
        _showSnackBar('Ошибка при сохранении записи', isError: true);
      }
    } catch (e) {
      _showSnackBar('Ошибка подключения к серверу.', isError: true);
    }
  }

  void _showAddOrEditPasswordDialog({dynamic password}) {
    final TextEditingController organizationController =
        TextEditingController(text: password?['organization_name'] ?? '');
    final TextEditingController nvrController =
        TextEditingController(text: password?['nvr_password'] ?? '');
    final TextEditingController cameraController =
        TextEditingController(text: password?['camera_password'] ?? '');

    bool _obscureNvr = true;
    bool _obscureCamera = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  20 + MediaQuery.of(context).padding.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: visionGray.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: hikRed.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              password == null
                                  ? Icons.add_business_outlined
                                  : Icons.edit_outlined,
                              color: hikRed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            password == null
                                ? 'Добавить запись'
                                : 'Редактировать запись',
                            style: GoogleFonts.montserrat(
                              color: darkGray,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: organizationController,
                        style: TextStyle(color: darkGray),
                        decoration: InputDecoration(
                          labelText: 'Название организации',
                          labelStyle: TextStyle(color: visionGray),
                          prefixIcon: Icon(Icons.business, color: visionGray),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: visionGray.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: hikRed),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: nvrController,
                        obscureText: _obscureNvr,
                        style: TextStyle(color: darkGray),
                        decoration: InputDecoration(
                          labelText: 'Пароль NVR',
                          labelStyle: TextStyle(color: visionGray),
                          prefixIcon: Icon(Icons.lock, color: visionGray),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNvr
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: visionGray,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNvr = !_obscureNvr;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: visionGray.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: hikRed),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: cameraController,
                        obscureText: _obscureCamera,
                        style: TextStyle(color: darkGray),
                        decoration: InputDecoration(
                          labelText: 'Пароль камеры',
                          labelStyle: TextStyle(color: visionGray),
                          prefixIcon: Icon(Icons.videocam, color: visionGray),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCamera
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: visionGray,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCamera = !_obscureCamera;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: visionGray.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: hikRed),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: visionGray,
                                side: BorderSide(
                                    color: visionGray.withOpacity(0.3)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Отмена',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                addOrEditPassword(
                                  id: password?['id'],
                                  organizationName:
                                      organizationController.text.trim(),
                                  nvrPassword: nvrController.text.trim(),
                                  cameraPassword: cameraController.text.trim(),
                                );
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hikRed,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Сохранить',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Метод для непосредственного выполнения удаления (без дополнительного диалога)
  Future<void> _performDeletePassword(int id) async {
    final token = await _getToken();
    if (token == null) {
      _showSnackBar('Токен не найден. Пожалуйста, войдите заново.',
          isError: true);
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('http://26.6.96.21:8000/sales/api/passwords/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          passwords.removeWhere((password) => password['id'] == id);
          filteredPasswords.removeWhere((password) => password['id'] == id);
          _expandedItems.remove(id);
        });
        _showSnackBar('Запись успешно удалена', isError: false);
      } else {
        _showSnackBar('Ошибка удаления: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Ошибка подключения к серверу.', isError: true);
    }
  }

  // Метод для показа диалога и удаления через кнопку в интерфейсе
  void deletePassword(int id) {
    AdaptiveAlertDialog.show(
      context: context,
      title: 'Подтверждение удаления',
      message: 'Вы уверены, что хотите удалить эту запись?',
      actions: [
        AlertAction(
          title: 'Отмена',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'Удалить',
          style: AlertActionStyle.destructive,
          onPressed: () => _performDeletePassword(id),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    showAppToast(context, message, isError: isError);
  }

  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('$type скопирован в буфер обмена', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AdaptiveScaffold(
        useHeroBackButton: false,
        appBar: AdaptiveAppBar(
          useNativeToolbar: true,
          title: 'Пароли (${filteredPasswords.length})',
          actions: [
            AdaptiveAppBarAction(
              iosSymbol: 'plus',
              icon: Icons.add,
              onPressed: () => _showAddOrEditPasswordDialog(),
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
                    _buildSearchBar(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchPasswords,
                        color: hikRed,
                        backgroundColor: Colors.white,
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(hikRed),
                                ),
                              )
                            : filteredPasswords.isEmpty
                                ? _buildEmptyState()
                                : _buildPasswordsList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 20, color: visionGray),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: searchController,
                cursorColor: hikRed,
                style: GoogleFonts.montserrat(color: darkGray, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Поиск по организации...',
                  hintStyle: GoogleFonts.montserrat(
                    color: visionGray.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  filterPasswords(value);
                  setState(() {});
                },
              ),
            ),
            if (searchController.text.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  searchController.clear();
                  filterPasswords('');
                  setState(() {});
                },
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: visionGray,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_open_outlined,
            size: 70,
            color: visionGray.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            searchController.text.isNotEmpty
                ? 'Нет паролей, соответствующих поиску'
                : 'Нет сохраненных паролей',
            style: GoogleFonts.montserrat(
              color: visionGray,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (searchController.text.isNotEmpty) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  searchController.clear();
                  filterPasswords('');
                });
              },
              icon: Icon(Icons.clear),
              label: Text('Очистить поиск'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hikRed,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredPasswords.length,
      physics: AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final password = filteredPasswords[index];
        final id = password['id'];
        final isExpanded = _expandedItems[id] ?? false;

        return Animate(
          effects: [FadeEffect(duration: 300.ms, delay: (50 * index).ms)],
          child: Dismissible(
            key: ValueKey(id),
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: Icon(Icons.edit, color: Colors.white),
            ),
            secondaryBackground: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: hikRed,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                _showAddOrEditPasswordDialog(password: password);
                return false;
              } else if (direction == DismissDirection.endToStart) {
                final completer = Completer<bool>();
                AdaptiveAlertDialog.show(
                  context: context,
                  title: 'Подтверждение удаления',
                  message: 'Вы уверены, что хотите удалить эту запись?',
                  actions: [
                    AlertAction(
                      title: 'Отмена',
                      style: AlertActionStyle.cancel,
                      onPressed: () => completer.complete(false),
                    ),
                    AlertAction(
                      title: 'Удалить',
                      style: AlertActionStyle.destructive,
                      onPressed: () => completer.complete(true),
                    ),
                  ],
                );
                return completer.future;
              }
              return false;
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                // Непосредственное удаление без повторного диалога
                _performDeletePassword(id);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _expandedItems[id] = !isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: hikRed.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.business_outlined,
                                color: hikRed,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    password['organization_name'] ??
                                        'Без названия',
                                    style: GoogleFonts.montserrat(
                                      color: darkGray,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isExpanded
                                          ? hikRed.withOpacity(0.12)
                                          : visionGray.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isExpanded
                                              ? Icons.lock_open_rounded
                                              : Icons.lock_outline_rounded,
                                          size: 12,
                                          color:
                                              isExpanded ? hikRed : visionGray,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          isExpanded
                                              ? 'Пароли открыты'
                                              : 'Нажмите, чтобы показать',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isExpanded
                                                ? hikRed
                                                : visionGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.edit_outlined,
                                color: visionGray,
                                size: 18,
                              ),
                              onPressed: () => _showAddOrEditPasswordDialog(
                                  password: password),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 200),
                              turns: isExpanded ? 0.5 : 0,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: visionGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      sizeCurve: Curves.easeInOut,
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            _buildPasswordItem(
                              icon: Icons.lock_outline,
                              title: 'Пароль NVR:',
                              password: password['nvr_password'] ?? '',
                              color: hikRed,
                              onCopy: () => _copyToClipboard(
                                  password['nvr_password'] ?? '', 'Пароль NVR'),
                            ),
                            SizedBox(height: 10),
                            _buildPasswordItem(
                              icon: Icons.videocam_outlined,
                              title: 'Пароль камеры:',
                              password: password['camera_password'] ?? '',
                              color: visionGray,
                              onCopy: () => _copyToClipboard(
                                  password['camera_password'] ?? '',
                                  'Пароль камеры'),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => deletePassword(id),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: hikRed,
                                  ),
                                  label: Text(
                                    'Удалить',
                                    style: GoogleFonts.montserrat(
                                      color: hikRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordItem({
    required IconData icon,
    required String title,
    required String password,
    required Color color,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: visionGray,
                    fontSize: 10,
                  ),
                ),
                Text(
                  password,
                  style: GoogleFonts.montserrat(
                    color: darkGray,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onCopy,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.copy_rounded,
                color: visionGray,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
