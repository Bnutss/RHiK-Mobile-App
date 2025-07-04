import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Цвета Hikvision
  final Color hikRed = Color(0xFFE31E24);
  final Color visionGray = Color(0xFF707070);
  final Color darkGray = Color(0xFF333333);
  final Color lightGray = Color(0xFFF5F5F5);

  Map<int, bool> _passwordVisibility = {};

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
        Uri.parse('https://rhik.pythonanywhere.com/sales/api/passwords/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          passwords = data;
          filteredPasswords = data;

          for (var password in data) {
            _passwordVisibility[password['id']] = false;
          }

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
              Uri.parse('https://rhik.pythonanywhere.com/sales/api/passwords/'),
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
              Uri.parse(
                  'https://rhik.pythonanywhere.com/sales/api/passwords/$id/'),
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                password == null ? 'Добавить запись' : 'Редактировать запись',
                style: GoogleFonts.montserrat(
                  color: hikRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Отмена',
                    style: GoogleFonts.montserrat(
                      color: visionGray,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    addOrEditPassword(
                      id: password?['id'],
                      organizationName: organizationController.text.trim(),
                      nvrPassword: nvrController.text.trim(),
                      cameraPassword: cameraController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hikRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Сохранить',
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
        Uri.parse('https://rhik.pythonanywhere.com/sales/api/passwords/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          passwords.removeWhere((password) => password['id'] == id);
          filteredPasswords.removeWhere((password) => password['id'] == id);
          _passwordVisibility.remove(id);
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
  Future<void> deletePassword(int id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Подтверждение удаления',
            style: GoogleFonts.montserrat(
              color: hikRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите удалить эту запись?',
            style: GoogleFonts.montserrat(
              color: darkGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Отмена',
                style: GoogleFonts.montserrat(
                  color: visionGray,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: hikRed,
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

    if (confirmDelete == true) {
      await _performDeletePassword(id);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: isError ? hikRed : visionGray,
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

  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('$type скопирован в буфер обмена', isError: false);
  }

  void _togglePasswordVisibility(int id) {
    setState(() {
      _passwordVisibility[id] = !(_passwordVisibility[id] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: hikRed,
        title: isSearching
            ? TextField(
                controller: searchController,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Поиск по организации...',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: filterPasswords,
                autofocus: true,
              )
            : Row(
                children: [
                  Icon(Icons.vpn_key_outlined, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Пароли (${filteredPasswords.length})',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  isSearching = false;
                  searchController.clear();
                  filterPasswords('');
                } else {
                  isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchPasswords,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: fetchPasswords,
            color: hikRed,
            backgroundColor: Colors.white,
            child: Column(
              children: [
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(hikRed),
                          ),
                        )
                      : filteredPasswords.isEmpty
                          ? _buildEmptyState()
                          : _buildPasswordsList(),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddOrEditPasswordDialog();
        },
        backgroundColor: hikRed,
        child: Icon(
          Icons.add,
          color: Colors.white,
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
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (searchController.text.isNotEmpty) {
                setState(() {
                  searchController.clear();
                  isSearching = false;
                  filterPasswords('');
                });
              } else {
                _showAddOrEditPasswordDialog();
              }
            },
            icon: Icon(
              searchController.text.isNotEmpty ? Icons.clear : Icons.add,
            ),
            label: Text(
              searchController.text.isNotEmpty
                  ? 'Очистить поиск'
                  : 'Добавить пароль',
            ),
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
        final isVisible = _passwordVisibility[id] ?? false;

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
                // Показываем диалог подтверждения
                bool? result = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Text(
                        'Подтверждение удаления',
                        style: GoogleFonts.montserrat(
                          color: hikRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        'Вы уверены, что хотите удалить эту запись?',
                        style: GoogleFonts.montserrat(
                          color: darkGray,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'Отмена',
                            style: GoogleFonts.montserrat(
                              color: visionGray,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hikRed,
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
                return result ?? false;
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                childrenPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hikRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business_outlined,
                    color: hikRed,
                  ),
                ),
                title: Text(
                  password['organization_name'] ?? 'Без названия',
                  style: GoogleFonts.montserrat(
                    color: darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Нажмите, чтобы показать пароли',
                  style: GoogleFonts.montserrat(
                    color: visionGray,
                    fontSize: 10,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        color: visionGray,
                        size: 20,
                      ),
                      onPressed: () => _togglePasswordVisibility(id),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: visionGray,
                        size: 20,
                      ),
                      onPressed: () =>
                          _showAddOrEditPasswordDialog(password: password),
                    ),
                  ],
                ),
                children: [
                  _buildPasswordItem(
                    icon: Icons.lock_outline,
                    title: 'Пароль NVR:',
                    password: password['nvr_password'] ?? '',
                    isVisible: isVisible,
                    color: hikRed,
                    onCopy: () => _copyToClipboard(
                        password['nvr_password'] ?? '', 'Пароль NVR'),
                  ),
                  SizedBox(height: 10),
                  _buildPasswordItem(
                    icon: Icons.videocam_outlined,
                    title: 'Пароль камеры:',
                    password: password['camera_password'] ?? '',
                    isVisible: isVisible,
                    color: visionGray,
                    onCopy: () => _copyToClipboard(
                        password['camera_password'] ?? '', 'Пароль камеры'),
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
        );
      },
    );
  }

  Widget _buildPasswordItem({
    required IconData icon,
    required String title,
    required String password,
    required bool isVisible,
    required Color color,
    required VoidCallback onCopy,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: darkGray,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            isVisible ? password : '••••••••',
            style: GoogleFonts.montserrat(
              color: darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.copy,
            color: visionGray,
            size: 20,
          ),
          onPressed: onCopy,
          tooltip: 'Копировать',
        ),
      ],
    );
  }
}
