import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ConfidentialityPage extends StatefulWidget {
  @override
  _ConfidentialityPageState createState() => _ConfidentialityPageState();
}

class _ConfidentialityPageState extends State<ConfidentialityPage>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isAuthenticated = false;
  bool _useBiometrics = false;
  bool _showPassword = false;
  bool _saveLoginData = true;
  List<BiometricType> _availableBiometrics = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _checkBiometrics();
    _loadBiometricPreference();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    List<BiometricType> availableBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
      availableBiometrics = await auth.getAvailableBiometrics();
      print("Available biometrics: $availableBiometrics");
    } catch (e) {
      canCheckBiometrics = false;
      availableBiometrics = <BiometricType>[];
      print("Error checking biometrics: $e");
    }
    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _loadBiometricPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? useBiometrics = prefs.getBool('useBiometrics');
    setState(() {
      _useBiometrics = useBiometrics ?? false;
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Для доступа к настройкам конфиденциальности',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      print("Authentication successful");
    } catch (e) {
      authenticated = false;
      print("Authentication error: $e");
    }
    if (!mounted) return;

    setState(() {
      _isAuthenticated = authenticated;
    });
  }

  Future<void> _toggleBiometricPreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _useBiometrics = value;
    });
    await prefs.setBool('useBiometrics', value);

    _showSnackBar(value
        ? 'Биометрическая аутентификация включена'
        : 'Биометрическая аутентификация отключена');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: hikRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: darkGray),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Конфиденциальность',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
                // Контент страницы
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _isAuthenticated
                        ? _buildAuthenticatedContent()
                        : _buildAuthenticationRequest(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedContent() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: hikRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_outlined,
                  size: 50,
                  color: hikRed,
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Настройки конфиденциальности',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkGray,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                'Настройте параметры безопасности для вашей учетной записи',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: visionGray,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40),
            _buildSettingsSection(
              'Аутентификация',
              [
                _buildToggleSettingsItem(
                  icon: Icons.fingerprint,
                  title: 'Биометрическая аутентификация',
                  subtitle: 'Использовать отпечаток пальца для входа',
                  value: _useBiometrics,
                  onChanged:
                      _canCheckBiometrics ? _toggleBiometricPreference : null,
                ),
                _buildToggleSettingsItem(
                  icon: Icons.login_outlined,
                  title: 'Сохранять данные для входа',
                  subtitle: 'Запоминать имя пользователя',
                  value: _saveLoginData,
                  onChanged: (value) {
                    setState(() {
                      _saveLoginData = value;
                    });
                    _showSnackBar(value
                        ? 'Данные для входа будут сохранены'
                        : 'Данные для входа не будут сохраняться');
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildSettingsSection(
              'Пароли и безопасность',
              [
                _buildSettingsItem(
                  icon: Icons.password_outlined,
                  title: 'Изменить пароль',
                  subtitle: 'Регулярно меняйте пароль для безопасности',
                  onTap: () {
                    _showChangePasswordDialog();
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.phonelink_lock_outlined,
                  title: 'Двухфакторная аутентификация',
                  subtitle: 'Дополнительный уровень защиты',
                  onTap: () {
                    _showComingSoonDialog();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildSettingsSection(
              'Конфиденциальность данных',
              [
                _buildSettingsItem(
                  icon: Icons.delete_outline,
                  title: 'Очистить кэш',
                  subtitle: 'Удалить временные файлы приложения',
                  onTap: () {
                    _showClearCacheDialog();
                  },
                ),
                _buildToggleSettingsItem(
                  icon: Icons.visibility_outlined,
                  title: 'Показывать пароли',
                  subtitle: 'Отображать пароли в текстовом виде',
                  value: _showPassword,
                  onChanged: (value) {
                    setState(() {
                      _showPassword = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animations/fingerprint.json',
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Требуется аутентификация',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Пожалуйста, пройдите биометрическую аутентификацию для доступа к настройкам конфиденциальности.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: visionGray,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    hikRed,
                    hikRed.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: hikRed.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _authenticate,
                icon: Icon(Icons.fingerprint, color: Colors.white, size: 24),
                label: Text(
                  'Аутентификация',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 10.0),
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkGray,
            ),
          ),
        ),
        Container(
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
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hikRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: hikRed, size: 22),
          ),
          title: Text(
            title,
            style: GoogleFonts.montserrat(
              color: darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.montserrat(
              color: visionGray,
              fontSize: 12,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: visionGray),
        ),
      ),
    );
  }

  Widget _buildToggleSettingsItem(
      {required IconData icon,
      required String title,
      required String subtitle,
      required bool value,
      required Function(bool)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hikRed.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: hikRed, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            color: darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.montserrat(
            color: visionGray,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: hikRed,
          activeTrackColor: hikRed.withOpacity(0.5),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: visionGray.withOpacity(0.3),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    TextEditingController _currentPasswordController = TextEditingController();
    TextEditingController _newPasswordController = TextEditingController();
    TextEditingController _confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Изменить пароль',
            style: GoogleFonts.montserrat(
              color: darkGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _currentPasswordController,
                  obscureText: !_showPassword,
                  style: TextStyle(color: darkGray),
                  decoration: InputDecoration(
                    labelText: 'Текущий пароль',
                    labelStyle: TextStyle(color: visionGray),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: visionGray.withOpacity(0.3)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: hikRed),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _newPasswordController,
                  obscureText: !_showPassword,
                  style: TextStyle(color: darkGray),
                  decoration: InputDecoration(
                    labelText: 'Новый пароль',
                    labelStyle: TextStyle(color: visionGray),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: visionGray.withOpacity(0.3)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: hikRed),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_showPassword,
                  style: TextStyle(color: darkGray),
                  decoration: InputDecoration(
                    labelText: 'Подтвердите пароль',
                    labelStyle: TextStyle(color: visionGray),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: visionGray.withOpacity(0.3)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: hikRed),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Отмена',
                style: GoogleFonts.montserrat(
                  color: visionGray,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    hikRed,
                    hikRed.withOpacity(0.8),
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSnackBar('Пароль успешно изменен');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Изменить',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Очистить кэш',
            style: GoogleFonts.montserrat(
              color: darkGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите очистить кэш приложения? Это не повлияет на ваши данные, но может потребоваться повторная загрузка некоторых элементов.',
            style: GoogleFonts.montserrat(
              color: visionGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Отмена',
                style: GoogleFonts.montserrat(
                  color: visionGray,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    hikRed,
                    hikRed.withOpacity(0.8),
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSnackBar('Кэш успешно очищен');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Очистить',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Скоро будет доступно',
            style: GoogleFonts.montserrat(
              color: darkGray,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Эта функция находится в разработке и будет доступна в ближайшем обновлении.',
            style: GoogleFonts.montserrat(
              color: visionGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Понятно',
                style: GoogleFonts.montserrat(
                  color: hikRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
